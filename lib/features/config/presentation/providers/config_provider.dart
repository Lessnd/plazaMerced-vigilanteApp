import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/config_repository.dart';

// Este provider mantiene la configuración viva y accesible en toda la app
final currentConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(configRepositoryProvider);
  return await repo.obtenerConfiguracion();
});