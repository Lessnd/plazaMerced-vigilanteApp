import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/models/configuracion.dart';

final configuracionProvider = FutureProvider<Configuracion?>((ref) async {
  print('🔄 [ConfigProvider] Cargando configuración...');
  try {
    final repo = ref.read(ticketRepositoryProvider);
    final data = await repo.obtenerConfiguracion();
    if (data == null) {
      print(
        '⚠️ [ConfigProvider] No hay configuración, usando valores por defecto',
      );
      return null;
    }
    final config = Configuracion.fromMap(data);
    print(
      '✅ [ConfigProvider] Configuración cargada: tarifa=${config.tarifaParqueoHora}',
    );
    return config;
  } catch (e, s) {
    print('❌ [ConfigProvider] Error: $e');
    print(s);
    rethrow;
  }
});
