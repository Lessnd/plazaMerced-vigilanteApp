import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ticket_repository_impl.dart';

final historyTicketsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(ticketRepositoryProvider);
  final allTickets = await repo.obtenerTodosLosTicketsCrudos();
  
  // Filtramos SOLO los que YA tienen fecha de salida (cerrados)
  final historial = allTickets.where((t) => t['salida'] != null).toList();
  
  // Ordenamos del cobro más reciente al más antiguo
  historial.sort((a, b) => DateTime.parse(b['salida']).compareTo(DateTime.parse(a['salida'])));
  
  // Tomamos solo los últimos 10 para no saturar la memoria
  return historial.take(10).toList();
});