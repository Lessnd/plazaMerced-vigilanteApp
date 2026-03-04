import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigilante_app/core/services/printer-service.dart';

import '../../../../core/utils/time_manager.dart';
import '../../../parking/data/repositories/ticket_repository_impl.dart';
import '../../../parking/domain/models/ticket.dart';
import '../../../config/presentation/providers/config_provider.dart';
import '../providers/active_ticket_provider.dart';
import '../providers/history_tickets_provider.dart';

import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/app_active_vehicle_card.dart';
import '../../../../shared/widgets/app_toast.dart';

class ActivosScreen extends ConsumerWidget {
  const ActivosScreen({super.key});

  Future<void> _mostrarConfirmacionCobro(
    BuildContext context,
    WidgetRef ref,
    Ticket ticket,
  ) async {
    final theme = Theme.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Salida Manual'),
        content: Text(
          '¿Deseas registrar la salida y cobrar el vehículo con placa ${ticket.placa}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cobrar Vehículo'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      _procesarSalidaManual(context, ref, ticket);
    }
  }

  Future<void> _procesarSalidaManual(
    BuildContext context,
    WidgetRef ref,
    Ticket ticket,
  ) async {
    try {
      final repo = ref.read(ticketRepositoryProvider);
      final horaVerdadera = ref.read(timeManagerProvider.notifier).getTrueTime();

      // Lectura REAL de la base de datos para la tarifa
      final config = await ref.read(currentConfigProvider.future);
      final double tarifaActual = (config['tarifaParqueoHora'] as num?)?.toDouble() ?? 1.0;
      final int cortesiaActual = (config['minutos_cortesia'] as num?)?.toInt() ?? 3;

      final ticketCerrado = await repo.registrarSalida(
        ticketId: ticket.id!,
        fechaSalida: horaVerdadera,
        tarifaActual: tarifaActual,
        cortesiaActual: cortesiaActual,
      );

      final minutosTotales = ticketCerrado.salida!.difference(ticketCerrado.entrada).inMinutes;

      // Inyección del Hardware (Simulado)
      await ref.read(printerServiceProvider).printExitReceipt(ticketCerrado, minutosTotales);

      // Reactividad global
      ref.invalidate(activeTicketsProvider);
      ref.invalidate(historyTicketsProvider);

      if (context.mounted) {
        AppToastService.show(
          context,
          'Cobro exitoso: \$${ticketCerrado.costo?.toStringAsFixed(2)}',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToastService.show(context, 'Error: $e', type: AppToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTicketsAsync = ref.watch(activeTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículos Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeTicketsProvider),
          ),
        ],
      ),
      body: activeTicketsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: AppSkeleton(height: 120), // Ajustado a la altura de la nueva tarjeta
          ),
        ),
        error: (error, stack) {
          return Center(
            child: Text(
              'Error al cargar datos: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        },
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay vehículos en el parqueo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: AppActiveVehicleCard(
                  ticket: ticket,
                  // El tap ahora dispara el flujo de cobro directamente
                  onTap: () => _mostrarConfirmacionCobro(context, ref, ticket),
                ),
              );
            },
          );
        },
      ),
    );
  }
}