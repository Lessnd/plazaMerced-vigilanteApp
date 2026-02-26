import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/ticket_repository_impl.dart';

// Este provider consultará la base de datos y traerá solo los vehículos en parqueo
final activeTicketsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(ticketRepositoryProvider);
  final allTickets = await repo.obtenerTodosLosTicketsCrudos();
  
  // Filtramos solo los que no tienen fecha de salida
  final activos = allTickets.where((t) => t['salida'] == null).toList();
  
  // Los ordenamos para que los más recientes (o más antiguos) salgan primero
  activos.sort((a, b) => DateTime.parse(b['entrada']).compareTo(DateTime.parse(a['entrada'])));
  
  return activos;
});