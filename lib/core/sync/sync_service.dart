import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';

// Repositorios
import '../../features/parking/data/repositories/ticket_repository_impl.dart';
import '../../features/banos/data/banos_repository.dart';

class SyncException implements Exception {
  final String message;
  final String technicalDetails;
  SyncException(this.message, {this.technicalDetails = ''});
  @override
  String toString() => message;
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

class SyncService {
  final Ref ref;
  bool _isSyncing = false;
  static const int _batchSize = 50; // Tamaño máximo por lote para no ahogar la red

  static const String baseUrl = 'http://192.168.1.100:3000/api'; 
  late final Dio _dio;

  SyncService(this.ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(responseBody: true, error: true));
    }
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final hasInternet = await ref.read(connectivityServiceProvider).isConnected;
      if (!hasInternet) throw SyncException('No hay conexión a internet.');

      await _uploadTickets();
      await _uploadBanos();
      await _downloadConfig();

      print('✅ [Sync] Ciclo de sincronización completado.');
    } finally {
      _isSyncing = false;
    }
  }

  // --- SUBIDA DE TICKETS (POR LOTES) ---
  Future<void> _uploadTickets() async {
    final repo = ref.read(ticketRepositoryProvider);
    final pending = await repo.obtenerPendientesSync();
    
    if (pending.isEmpty) return;
    print('🔼 [Sync] Subiendo ${pending.length} tickets en lotes de $_batchSize...');

    for (var i = 0; i < pending.length; i += _batchSize) {
      final chunk = pending.sublist(i, i + _batchSize > pending.length ? pending.length : i + _batchSize);
      final ticketsJson = chunk.map((t) => t.toJsonForServer()).toList();

      try {
        final response = await _dio.post('/parqueo/sync', data: {'tickets': ticketsJson});
        
        if (response.statusCode == 200 && response.data['success'] == true) {
          // Éxito: marcamos solo los de este lote como subidos
          for (var ticket in chunk) {
            await repo.marcarSincronizado(ticket.serverId, error: false);
          }
        } else {
          throw SyncException('Error del servidor: ${response.data['message']}');
        }
      } on DioException catch (e) {
        _handleDioError(e, chunk, (id) => repo.marcarSincronizado(id, error: true), isTicket: true);
      }
    }
  }

  // --- SUBIDA DE BAÑOS (POR LOTES) ---
  Future<void> _uploadBanos() async {
    final repo = ref.read(banosRepositoryProvider);
    final pending = await repo.obtenerPendientesSync();
    
    if (pending.isEmpty) return;
    print('🔼 [Sync] Subiendo ${pending.length} registros de baños...');

    for (var i = 0; i < pending.length; i += _batchSize) {
      final chunk = pending.sublist(i, i + _batchSize > pending.length ? pending.length : i + _batchSize);

      try {
        final response = await _dio.post('/banos/sync', data: {'banos': chunk});
        
        if (response.statusCode == 200 && response.data['success'] == true) {
          for (var bano in chunk) {
            await repo.marcarSincronizado(bano['id'] as int, error: false);
          }
        }
      } on DioException catch (e) {
        _handleDioError(e, chunk, (id) => repo.marcarSincronizado(id, error: true), isTicket: false);
      }
    }
  }

  // --- DESCARGA DE CONFIGURACIÓN ---
  Future<void> _downloadConfig() async {
    try {
      final response = await _dio.get('/config');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final repo = ref.read(ticketRepositoryProvider);
        await repo.actualizarConfiguracion(response.data['data']);
      }
    } catch (e) {
      print('⚠️ [Sync] Fallo descarga de configuración, continuando... $e');
    }
  }

  // --- MANEJO INTELIGENTE DE ERRORES ---
  void _handleDioError(DioException e, List<dynamic> chunk, Future<void> Function(dynamic id) markError, {required bool isTicket}) {
    // Si es un error 4XX (Bad Request), los datos están corruptos. Lo marcamos como Error (sincronizado = 2)
    // para que no tranque el bucle infinito. 
    if (e.response != null && e.response!.statusCode! >= 400 && e.response!.statusCode! < 500) {
      print('❌ [Sync] Datos rechazados por el servidor. Marcando como error duro.');
      for (var item in chunk) {
        final id = isTicket ? item.serverId : item['id'];
        markError(id);
      }
      throw SyncException('Datos inválidos enviados al servidor', technicalDetails: e.toString());
    } 
    // Si es un timeout o error 500, es culpa de la red/servidor. NO marcamos error local, 
    // los dejamos en 0 para que se reintenten en la próxima ejecución.
    else {
      print('⏳ [Sync] Error de red o servidor caído. Se retendrán para el próximo lote.');
      throw SyncException('Fallo de conexión en lote. Se reintentará luego.', technicalDetails: e.toString());
    }
  }
}