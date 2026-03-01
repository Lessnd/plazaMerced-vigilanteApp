import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/time_manager.dart';
import '../../../parking/data/repositories/ticket_repository_impl.dart';
import 'package:vigilante_app/features/parking/presentation/providers/active_ticket_provider.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import 'package:vigilante_app/shared/widgets/app_active_vehicle_card.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../parking/domain/models/ticket.dart'; // 🔄 CAMBIO: Importar el modelo Ticket

class ActivosScreen extends ConsumerWidget {
  const ActivosScreen({super.key});

  // 🔄 CAMBIO: El método ahora recibe DateTime directamente
  String _calcularTiempo(DateTime entrada, DateTime horaActual) {
    final diferencia = horaActual.difference(entrada);
    if (diferencia.inHours > 0) {
      return '${diferencia.inHours}h ${diferencia.inMinutes.remainder(60)}m';
    }
    return '${diferencia.inMinutes} minutos';
  }

  // 🔄 CAMBIO: El parámetro ahora es de tipo Ticket
  Future<void> _mostrarConfirmacionCobro(
    BuildContext context,
    WidgetRef ref,
    Ticket ticket, // <-- Cambio aquí
  ) async {
    final theme = Theme.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Salida Manual'),
        content: Text(
          '¿Deseas cobrar el vehículo con placa ${ticket.placa}?', // 🔄 Usamos ticket.placa
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
      print(
        '💲 [Activos] Usuario confirmó cobro manual para ticket ${ticket.id}', // 🔄 ticket.id
      );
      _procesarSalidaManual(
        context,
        ref,
        ticket.id!,
      ); // ticket.id (puede ser null, usamos ! si seguro)
    }
  }

  Future<void> _procesarSalidaManual(
    BuildContext context,
    WidgetRef ref,
    int ticketId,
  ) async {
    print('💲 [Activos] Iniciando cobro manual para ticket $ticketId');
    try {
      final repo = ref.read(ticketRepositoryProvider);
      final horaVerdadera = ref
          .read(timeManagerProvider.notifier)
          .getTrueTime();

      final resultado = await repo.registrarSalida(
        ticketId: ticketId,
        fechaSalida: horaVerdadera,
        tarifaActual: 1.0,
        cortesiaActual: 3,
      );

      ref.invalidate(activeTicketsProvider);

      if (context.mounted) {
        AppToastService.show(
          context,
          'Cobro exitoso: \$${resultado.costo}',
          type: AppToastType.success,
        );
        print('✅ [Activos] Cobro manual exitoso para ticket $ticketId');
      }
    } catch (e, s) {
      print('❌ [Activos] Error en cobro manual: $e');
      print(s);
      if (context.mounted) {
        AppToastService.show(context, 'Error: $e', type: AppToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTicketsAsync = ref.watch(activeTicketsProvider);
    final horaActualBlindada = ref
        .watch(timeManagerProvider.notifier)
        .getTrueTime();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículos Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 [Activos] Recarga manual de activos');
              ref.invalidate(activeTicketsProvider);
            },
          ),
        ],
      ),
      body: activeTicketsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: AppSkeleton(height: 80),
          ),
        ),
        error: (error, stack) {
          print('❌ [Activos] Error en provider: $error');
          return Center(
            child: Text(
              'Error al cargar datos: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        },
        data: (tickets) {
          // 🔄 tickets ahora es List<Ticket>
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
              final ticket = tickets[index]; // 🔄 Es Ticket
              final tiempoTranscurrido = _calcularTiempo(
                ticket.entrada, // 🔄 Propiedad DateTime
                horaActualBlindada,
              );

              return AppActiveVehicleCard(
                placa: ticket.placa, // 🔄 Propiedad
                tiempo: tiempoTranscurrido,
                isSyncPending: ticket.sincronizado == 0, // 🔄 Propiedad
                onCobrar: () => _mostrarConfirmacionCobro(
                  context,
                  ref,
                  ticket,
                ), // 🔄 Pasamos ticket
              );
            },
          );
        },
      ),
    );
  }
}
