import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigilante_app/core/database/app_database.dart';
import 'package:vigilante_app/core/sync/connectivity_service.dart';
import 'package:vigilante_app/features/parking/data/repositories/ticket_repository_impl.dart';

// Excepción personalizada para errores de sincronización
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

  // Configurable: URL base del backend (debería venir de una fuente externa)
  static const String baseUrl =
      'http://192.168.1.100:3000/api'; // Cambia por tu IP real

  // Instancia de Dio con configuración por defecto
  late final Dio _dio;

  SyncService(this.ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Opcional: agregar interceptor para logging en desarrollo
    if (!(ref.read(connectivityServiceProvider).isConnected as bool)) {
      // No logueamos aquí, pero se puede agregar un interceptor
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          responseHeader: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  Future<void> syncAll() async {
    if (_isSyncing) {
      print('🔄 [Sync] Ya hay una sincronización en curso, ignorando...');
      return;
    }
    _isSyncing = true;
    print('🔄 [Sync] Iniciando sincronización completa...');

    try {
      final connectivity = ref.read(connectivityServiceProvider);
      final hasInternet = await connectivity.isConnected;
      if (!hasInternet) {
        throw SyncException(
          'No hay conexión a internet. Conéctate e inténtalo de nuevo.',
        );
      }

      await _upload();
      await _download();

      print('✅ [Sync] Sincronización completada exitosamente.');
    } catch (e, stack) {
      print('❌ [Sync] Error durante sincronización: $e');
      print('📄 [Sync] StackTrace: $stack');
      if (e is SyncException) rethrow;
      throw SyncException('Error inesperado: ${e.toString()}');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sube todos los tickets pendientes (sincronizado = 0) al endpoint /sync
  Future<void> _upload() async {
    final repo = ref.read(ticketRepositoryProvider);
    final pending = await repo
        .obtenerPendientesSync(); // debe devolver List<Ticket> o List<Map>
    if (pending.isEmpty) {
      print('🔼 [Sync] No hay tickets pendientes de subir.');
      return;
    }

    print('🔼 [Sync] Subiendo ${pending.length} tickets pendientes...');

    // Construir payload: asumimos que cada ticket tiene un método toJsonForServer()
    final ticketsJson = pending.map((t) => t.toJsonForServer()).toList();

    try {
      final response = await _dio.post(
        '/parqueo/sync',
        data: {'tickets': ticketsJson},
      );

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true) {
          // Marcar todos como sincronizados (asumimos éxito total)
          for (var ticket in pending) {
            await repo.marcarSincronizado(ticket.id.toString(), error: false);
          }
          print(
            '✅ [Sync] Subida exitosa, ${pending.length} tickets marcados como sincronizados.',
          );
        } else {
          throw SyncException(
            'El servidor respondió con error: ${body['message']}',
          );
        }
      } else {
        throw SyncException(
          'Error HTTP ${response.statusCode}: ${response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      // Manejar errores específicos de Dio
      for (var ticket in pending) {
        await repo.marcarSincronizado(ticket.serverId, error: true);
      }

      String errorMessage = 'Error en la subida';
      String technical = e.toString();

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Tiempo de espera agotado. Intenta más tarde.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'No se pudo conectar al servidor. Verifica la dirección IP o la red.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage =
            'El servidor respondió con error ${e.response?.statusCode}.';
        technical = e.response?.data.toString() ?? e.toString();
      } else if (e.type == DioExceptionType.cancel) {
        errorMessage = 'La petición fue cancelada.';
      } else {
        errorMessage = 'Error de red: ${e.message}';
      }

      print('❌ [Sync] Error en subida: $e');
      throw SyncException(errorMessage, technicalDetails: technical);
    } catch (e) {
      // Otros errores no controlados
      for (var ticket in pending) {
        await repo.marcarSincronizado(ticket.serverId, error: true);
      }
      print('❌ [Sync] Error inesperado en subida: $e');
      rethrow;
    }
  }

  /// Descarga la configuración desde /api/config y actualiza la tabla local
  Future<void> _download() async {
    print('🔽 [Sync] Descargando configuración del servidor...');
    try {
      final response = await _dio.get('/config');

      if (response.statusCode == 200) {
        final body = response.data;
        if (body['success'] == true && body['data'] != null) {
          final repo = ref.read(ticketRepositoryProvider);
          await repo.actualizarConfiguracion(body['data']);
          print('✅ [Sync] Configuración descargada y actualizada.');
        } else {
          throw SyncException(
            'Error al obtener configuración: ${body['message']}',
          );
        }
      } else {
        throw SyncException(
          'Error HTTP ${response.statusCode} al descargar configuración.',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Error en descarga';
      String technical = e.toString();

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Tiempo de espera agotado al descargar.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No se pudo conectar al servidor para descargar.';
      } else if (e.type == DioExceptionType.badResponse) {
        errorMessage =
            'El servidor respondió con error ${e.response?.statusCode}.';
        technical = e.response?.data.toString() ?? e.toString();
      } else {
        errorMessage = 'Error de red: ${e.message}';
      }

      print('❌ [Sync] Error en descarga: $e');
      throw SyncException(errorMessage, technicalDetails: technical);
    } catch (e) {
      print('❌ [Sync] Error inesperado en descarga: $e');
      rethrow;
    }
  }
}
