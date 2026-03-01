import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigilante_app/core/sync/sync_service.dart';

final isSyncingProvider = StateProvider<bool>((ref) => false);
final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);

// Provider para lanzar sincronización manual
final syncNowProvider = FutureProvider<void>((ref) async {
  final syncService = ref.read(syncServiceProvider);
  ref.read(isSyncingProvider.notifier).state = true;
  try {
    await syncService.syncAll();
    ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();
  } finally {
    ref.read(isSyncingProvider.notifier).state = false;
  }
});