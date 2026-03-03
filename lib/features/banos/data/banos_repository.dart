import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

// El Provider para inyectar este repositorio
final banosRepositoryProvider = Provider<BanosRepository>((ref) {
  return BanosRepository();
});

class BanosRepository {
  /// Registra un nuevo cobro de baño en la base de datos local
  Future<int> registrarUsoBano({
    required double tarifaCobrada,
    required String fechaUso,
    required String deviceId,
  }) async {
    final db = await AppDatabase.instance.database;
    
    // Insertamos basándonos exactamente en el esquema que dejó tu compañero
    return await db.insert('Banos', {
      'tarifaCobrada': tarifaCobrada,
      'fechaUso': fechaUso,
      'deviceId': deviceId,
      'sincronizado': 0, // Siempre nace pendiente de subir al servidor
    });
  }

  // Obtiene los cobros de baño que no han subido al servidor
  Future<List<Map<String, dynamic>>> obtenerPendientesSync() async {
    final db = await AppDatabase.instance.database;
    return await db.query('Banos', where: 'sincronizado = ?', whereArgs: [0]);
  }

  // Actualiza el estado del cobro tras intentar subirlo
  Future<void> marcarSincronizado(int id, {required bool error}) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'Banos',
      {'sincronizado': error ? 2 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}