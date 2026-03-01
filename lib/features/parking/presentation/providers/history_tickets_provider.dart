import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/models/ticket.dart';

final historyTicketsProvider = FutureProvider.autoDispose<List<Ticket>>((
  ref,
) async {
  print('🔄 [HistoryTicketsProvider] Cargando historial...');
  try {
    final repo = ref.read(ticketRepositoryProvider);
    final allTickets = await repo.obtenerTodosLosTickets();
    final historial = allTickets.where((t) => t.salida != null).toList();
    historial.sort((a, b) => b.salida!.compareTo(a.salida!));
    final ultimos = historial.take(10).toList();
    print('✅ [HistoryTicketsProvider] ${ultimos.length} registros cargados.');
    return ultimos;
  } catch (e, s) {
    print('❌ [HistoryTicketsProvider] Error: $e');
    print(s);
    rethrow;
  }
});
