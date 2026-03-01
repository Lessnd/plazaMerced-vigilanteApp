import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/models/ticket.dart';

final activeTicketsProvider = FutureProvider.autoDispose<List<Ticket>>((
  ref,
) async {
  print('🔄 [ActiveTicketsProvider] Cargando vehículos activos...');
  try {
    final repo = ref.read(ticketRepositoryProvider);
    final allTickets = await repo.obtenerTodosLosTickets();
    final activos = allTickets.where((t) => t.salida == null).toList();
    activos.sort((a, b) => b.entrada.compareTo(a.entrada));
    print('✅ [ActiveTicketsProvider] ${activos.length} activos cargados.');
    return activos;
  } catch (e, s) {
    print('❌ [ActiveTicketsProvider] Error: $e');
    print(s);
    rethrow;
  }
});
