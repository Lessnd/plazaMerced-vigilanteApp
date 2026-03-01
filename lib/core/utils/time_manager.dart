import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ntp/ntp.dart';
import 'package:vigilante_app/core/database/app_database.dart';

class TimeManager extends AsyncNotifier<int> {
  static const int _limiteToleranciaMs = 60000; // 1 minuto de tolerancia

  @override
  FutureOr<int> build() async {
    // Al iniciar, leemos el offset guardado para operar offline inmediatamente
    return await _getSavedOffset();
  }

  Future<int> _getSavedOffset() async {
    final db = await AppDatabase.instance.database;
    final List<Map<String, dynamic>> config = await db.query('Configuracion', limit: 1);
    
    if (config.isNotEmpty && config.first['timeOffset'] != null) {
      return config.first['timeOffset'] as int;
    }
    return 0;
  }

  Future<void> syncTimeWithNTP() async {
    state = const AsyncValue.loading();

    try {
      final db = await AppDatabase.instance.database;
      
      // 1. Obtenemos la hora real y la local
      final DateTime myTime = DateTime.now();
      final DateTime ntpTime = await NTP.now(timeout: const Duration(seconds: 5));
      
      // 2. Calculamos la mentira (offset)
      final int nuevoOffset = ntpTime.difference(myTime).inMilliseconds;
      
      // 3. Auditoría de fraude: comparamos con el offset anterior
      final int offsetAnterior = await _getSavedOffset();
      final int diferenciaManipulacion = (nuevoOffset - offsetAnterior).abs();

      bool esManipulado = diferenciaManipulacion > _limiteToleranciaMs && offsetAnterior != 0;

      // Si detectamos manipulación, podrías lanzar una alerta global o registrarlo.
      // Por ahora, actualizamos la configuración en la DB.
      
      final List<Map<String, dynamic>> config = await db.query('Configuracion', limit: 1);
      
      if (config.isEmpty) {
        // Si no hay configuración inicial, la creamos
        await db.insert('Configuracion', {
          'tarifaParqueoHora': 1.0, // Valores por defecto
          'tarifaBano': 0.5,
          'ultimaActualizacion': DateTime.now().toIso8601String(),
          'timeOffset': nuevoOffset,
        });
      } else {
        // Actualizamos el offset
        await db.update(
          'Configuracion',
          {'timeOffset': nuevoOffset},
          where: 'id = ?',
          whereArgs: [config.first['id']],
        );
      }

      // 4. Actualizamos el estado de Riverpod
      state = AsyncValue.data(nuevoOffset);

      if (esManipulado) {
        print("🚨 ALERTA: Se detectó un cambio brusco en el reloj local.");
        // Aquí puedes despachar un evento o guardar un log de seguridad
      }

    } catch (e) {
      // Si falla por falta de internet, recaemos en el offset guardado (offline mode)
      final offsetGuardado = await _getSavedOffset();
      state = AsyncValue.data(offsetGuardado);
      print("Sincronización NTP fallida, operando offline con offset: $offsetGuardado");
    }
  }

  /// Método expuesto para obtener la hora exacta en cualquier parte de la app
  DateTime getTrueTime() {
    final offsetActual = state.valueOrNull ?? 0;
    return DateTime.now().add(Duration(milliseconds: offsetActual));
  }
}

// El provider que inyectarás en tu UI y lógicas
final timeManagerProvider = AsyncNotifierProvider<TimeManager, int>(() {
  return TimeManager();
});