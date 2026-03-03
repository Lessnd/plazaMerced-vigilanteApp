import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_service.dart';

// El Notifier moderno que expone la fecha del último sync y maneja el estado de carga (loading) automáticamente.
final syncProvider = AsyncNotifierProvider<SyncNotifier, DateTime?>(SyncNotifier.new);

class SyncNotifier extends AsyncNotifier<DateTime?> {
  @override
  FutureOr<DateTime?> build() => null; // null significa que no hay sincronización previa en esta sesión

  Future<void> syncNow() async {
    // Si ya está cargando, bloqueamos ejecuciones duplicadas
    if (state.isLoading) return; 
    
    // Pasamos el estado a "cargando" para que la UI gire el spinner
    state = const AsyncValue.loading();
    
    try {
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncAll();
      
      // Si el éxito es total, guardamos la hora actual
      state = AsyncValue.data(DateTime.now());
    } catch (e, st) {
      // Si falla, Riverpod captura el error y lo expone a la UI
      state = AsyncValue.error(e, st);
    }
  }
}