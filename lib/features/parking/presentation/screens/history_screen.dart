import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../parking/presentation/providers/history_tickets_provider.dart';
import '../../../../shared/widgets/app_vehicle_card.dart';
import '../../../../shared/widgets/app_skeleton.dart';

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
            onPressed: () => ref.invalidate(historyTicketsProvider),
          )
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
        error: (error, stack) => Center(
          child: Text('Error: $error', style: TextStyle(color: theme.colorScheme.error)),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: theme.colorScheme.secondary),
                  const SizedBox(height: 16),
                  Text('No hay cobros recientes', style: theme.textTheme.titleMedium),
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
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    
                    // Calculamos los minutos totales reales entre entrada y salida
                    final entrada = DateTime.parse(ticket['entrada']);
                    final salida = DateTime.parse(ticket['salida']);
                    final minutos = salida.difference(entrada).inMinutes;

                    return AppVehicleCard(
                      placa: ticket['placa'] as String,
                      tiempo: '$minutos min',
                      monto: '\$${ticket['costo']}', // Inyectamos el costo para que la UI sepa que está cerrado
                      isSyncPending: ticket['sincronizado'] == 0,
                      onTap: null, // Solo lectura
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