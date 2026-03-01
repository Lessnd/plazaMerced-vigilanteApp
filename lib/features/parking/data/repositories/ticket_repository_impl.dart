import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vigilante_app/core/database/app_database.dart';
import 'package:vigilante_app/features/parking/domain/calculadora_tarifa.dart';
import 'package:vigilante_app/features/parking/domain/models/ticket.dart';
import 'package:riverpod/riverpod.dart';

part 'ticket_repository_impl.g.dart';

class TicketRepositoryImpl {
  final AppDatabase _dbHelper = AppDatabase.instance;

  /// Registra una entrada, generando un UUID para serverId.
  Future<Ticket> registrarEntrada({
    required String placa,
    required String deviceId,
    required DateTime fechaEntrada,
    required double tarifaAplicada,
    String? generacionId,
  }) async {
    print(
      '📝 [TicketRepo] registrarEntrada: placa=$placa, device=$deviceId, fecha=$fechaEntrada',
    );
    final db = await _dbHelper.database;

    final ticket = Ticket.entrada(
      placa: placa,
      deviceId: deviceId,
      entrada: fechaEntrada,
      tarifaAplicada: tarifaAplicada,
      generacionId: generacionId,
    );

    try {
      final id = await db.insert('Tickets', ticket.toMap());
      print(
        '✅ [TicketRepo] Entrada registrada con ID local: $id, serverId: ${ticket.serverId}',
      );
      return ticket.copyWith(id: id);
    } catch (e, s) {
      print('❌ [TicketRepo] Error al registrar entrada: $e');
      print(s);
      rethrow;
    }
  }

  /// Registra una salida (cálculo de costo) y marca como no sincronizado.
  Future<Ticket> registrarSalida({
    required int ticketId,
    required DateTime fechaSalida,
    required double tarifaActual,
    required int cortesiaActual,
  }) async {
    print(
      '📝 [TicketRepo] registrarSalida: ticketId=$ticketId, fechaSalida=$fechaSalida',
    );
    final db = await _dbHelper.database;

    try {
      // Obtener ticket actual
      final List<Map<String, dynamic>> rows = await db.query(
        'Tickets',
        where: 'id = ? AND salida IS NULL',
        whereArgs: [ticketId],
      );
      if (rows.isEmpty) {
        throw Exception('El ticket $ticketId no existe o ya fue cerrado.');
      }
      final ticket = Ticket.fromMap(rows.first);

      final costo = CalculadoraTarifa.calcularCosto(
        entrada: ticket.entrada,
        salida: fechaSalida,
        tarifaHora: tarifaActual,
        minutosCortesia: cortesiaActual,
      );

      final updatedTicket = ticket.copyWith(
        salida: fechaSalida,
        costo: costo,
        sincronizado: 0, // Pendiente de sincronizar
      );

      await db.update(
        'Tickets',
        updatedTicket.toMap(),
        where: 'id = ?',
        whereArgs: [ticketId],
      );

      print('✅ [TicketRepo] Salida registrada, costo: $costo');
      return updatedTicket;
    } catch (e, s) {
      print('❌ [TicketRepo] Error al registrar salida: $e');
      print(s);
      rethrow;
    }
  }

  /// Obtiene todos los tickets (para providers)
  Future<List<Ticket>> obtenerTodosLosTickets() async {
    print('📝 [TicketRepo] obteniendo todos los tickets');
    final db = await _dbHelper.database;
    try {
      final results = await db.query('Tickets', orderBy: 'id DESC');
      return results.map((map) => Ticket.fromMap(map)).toList();
    } catch (e, s) {
      print('❌ [TicketRepo] Error al obtener tickets: $e');
      print(s);
      rethrow;
    }
  }

  /// Obtiene tickets pendientes de sincronizar (sincronizado = 0)
  Future<List<Ticket>> obtenerPendientesSync() async {
    final db = await _dbHelper.database;
    final results = await db.query('Tickets', where: 'sincronizado = 0');
    return results.map((map) => Ticket.fromMap(map)).toList();
  }

  /// Actualiza el estado de sincronización de un ticket
  Future<void> marcarSincronizado(String serverId, {bool error = false}) async {
    final db = await _dbHelper.database;
    await db.update(
      'Tickets',
      {'sincronizado': error ? 2 : 1},
      where: 'serverId = ?',
      whereArgs: [serverId],
    );
  }

  /// Obtiene la configuración actual
  Future<Map<String, dynamic>?> obtenerConfiguracion() async {
    final db = await _dbHelper.database;
    final result = await db.query('Configuracion', limit: 1);
    if (result.isEmpty) return null;
    return result.first;
  }

  /// Actualiza la configuración local desde el servidor
  Future<void> actualizarConfiguracion(Map<String, dynamic> config) async {
    final db = await _dbHelper.database;
    await db.insert('Configuracion', {
      'id': 1,
      'tarifaParqueoHora': config['precio_hora'],
      'tarifaBano': 0.5, // Ajusta según tu backend
      'ultimaActualizacion': DateTime.now().toIso8601String(),
      'timeOffset': 0, // No se toca
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

@Riverpod(keepAlive: true)
TicketRepositoryImpl ticketRepository(Ref ref) {
  return TicketRepositoryImpl();
}
