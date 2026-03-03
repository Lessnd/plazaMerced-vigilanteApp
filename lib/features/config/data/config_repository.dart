import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

// El Provider de inyección, sin necesidad de generadores
final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepository();
});

class ConfigRepository {
  // Obtenemos la configuración actual del parqueo
  Future<Map<String, dynamic>> obtenerConfiguracion() async {
    final db = await AppDatabase.instance.database;
    
    // Asumimos que tu tabla se llama 'Configuracion' y tiene un solo registro maestro
    final result = await db.query('Configuracion', limit: 1);
    
    if (result.isNotEmpty) {
      return result.first;
    } else {
      // Si por algún motivo la base de datos está vacía, retornamos un fallback de emergencia
      // (Lo ideal es que AppDatabase inserte esto por defecto al crearse)
      return {
        'tarifa_hora': 1.0,
        'minutos_cortesia': 3,
      };
    }
  }

  // Método preparado para cuando hagas la pantalla de Ajustes
  Future<void> actualizarTarifa(double nuevaTarifa, int nuevaCortesia) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'Configuracion',
      {
        'tarifa_hora': nuevaTarifa,
        'minutos_cortesia': nuevaCortesia,
      },
    );
  }
}