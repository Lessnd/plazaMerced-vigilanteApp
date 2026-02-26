import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vigilante_app/core/database/app_database.dart';
import 'package:vigilante_app/features/parking/domain/calculadora_tarifa.dart';

// El generador creará el provider
part 'ticket_repository_impl.g.dart';

class TicketRepositoryImpl {
  final AppDatabase _dbHelper = AppDatabase.instance;

  Future<int> registrarEntrada({
    required String placa,
    required String deviceId,
    required DateTime fechaEntrada,
  }) async {
    final db = await _dbHelper.database;
    return await db.rawInsert('''
      INSERT INTO Tickets (placa, deviceId, entrada, sincronizado) 
      VALUES (?, ?, ?, 0)
    ''', [placa, deviceId, fechaEntrada.toIso8601String()]);
  }

  // Método para registrar la salida y calcular el cobro
  Future<Map<String, dynamic>> registrarSalida({
    required int ticketId,
    required DateTime fechaSalida,
    // Estos dos valores en el futuro vendrán de la tabla Configuracion.
    // Hoy los pasamos por parámetro para la prueba.
    required double tarifaActual, 
    required int cortesiaActual,
  }) async {
    final db = await _dbHelper.database;

    // 1. Buscar el ticket para saber a qué hora entró
    final List<Map<String, dynamic>> resultados = await db.rawQuery(
      'SELECT entrada FROM Tickets WHERE id = ? AND salida IS NULL',
      [ticketId],
    );

    if (resultados.isEmpty) {
      throw Exception('El ticket $ticketId no existe o ya fue cerrado.');
    }

    final fechaEntradaStr = resultados.first['entrada'] as String;
    final fechaEntrada = DateTime.parse(fechaEntradaStr);

    // 2. Calcular el costo usando nuestro dominio puro
    final costoCalculado = CalculadoraTarifa.calcularCosto(
      entrada: fechaEntrada,
      salida: fechaSalida,
      tarifaHora: tarifaActual,
      minutosCortesia: cortesiaActual,
    );

    // 3. Actualizar el registro en la base de datos (Guardamos el dinero y la hora)
    await db.rawUpdate('''
      UPDATE Tickets 
      SET salida = ?, costo = ?, sincronizado = 0 
      WHERE id = ?
    ''', [fechaSalida.toIso8601String(), costoCalculado, ticketId]);

    // Devolvemos el resultado para que la UI le diga al vigilante cuánto cobrar
    return {
      'costo': costoCalculado,
      'minutos_totales': fechaSalida.difference(fechaEntrada).inMinutes,
    };
  }

  Future<List<Map<String, dynamic>>> obtenerTodosLosTicketsCrudos() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('SELECT * FROM Tickets ORDER BY id DESC');
  }
}

// Magia de Riverpod: Proveedor global y cacheado del repositorio
@Riverpod(keepAlive: true)
TicketRepositoryImpl ticketRepository(TicketRepositoryRef ref) {
  return TicketRepositoryImpl();
}