import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../parking/presentation/providers/history_tickets_provider.dart';
import '../../../../shared/widgets/app_vehicle_card.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../parking/domain/models/ticket.dart'; // 🔄 CAMBIO: Importar Ticket

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyTicketsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial Reciente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 [History] Recarga manual de historial');
              ref.invalidate(historyTicketsProvider);
            },
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: AppSkeleton(height: 80),
          ),
        ),
        error: (error, stack) {
          print('❌ [History] Error en provider: $error');
          return Center(
            child: Text(
              'Error: $error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          );
        },
        data: (tickets) {
          // 🔄 CAMBIO: tickets ahora es List<Ticket>
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay cobros recientes',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Últimos ${tickets.length} movimientos',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index]; // 🔄 CAMBIO: es Ticket

                    // 🔄 CAMBIO: Usar propiedades del modelo
                    // En historial, ticket.salida nunca es nulo porque filtramos
                    final minutos = ticket.salida!
                        .difference(ticket.entrada)
                        .inMinutes;

                    return AppVehicleCard(
                      placa: ticket.placa,
                      tiempo: '$minutos min',
                      // 🔄 CAMBIO: Formatear costo con 2 decimales
                      monto: '\$${ticket.costo?.toStringAsFixed(2)}',
                      isSyncPending: ticket.sincronizado == 0,
                      onTap: null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
