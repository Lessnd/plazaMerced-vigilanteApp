import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigilante_app/core/theme/app_theme.dart';
import '../../../../core/utils/time_manager.dart';
import '../../../parking/data/repositories/ticket_repository_impl.dart';
import 'package:vigilante_app/features/parking/presentation/providers/active_ticket_provider.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import 'package:vigilante_app/shared/widgets/app_active_vehicle_card.dart';

class ActivosScreen extends ConsumerWidget {
  const ActivosScreen({super.key});

  // Función para calcular el tiempo visible en la tarjeta de forma rápida
  String _calcularTiempo(String entradaIso, DateTime horaActual) {
    final entrada = DateTime.parse(entradaIso);
    final diferencia = horaActual.difference(entrada);
    if (diferencia.inHours > 0) {
      return '${diferencia.inHours}h ${diferencia.inMinutes.remainder(60)}m';
    }
    return '${diferencia.inMinutes} minutos';
  }

  // Diálogo de confirmación para cobro manual (Plan B)
  Future<void> _mostrarConfirmacionCobro(BuildContext context, WidgetRef ref, Map<String, dynamic> ticket) async {
    final theme = Theme.of(context);
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Salida Manual'),
        content: Text('¿Deseas registrar la salida y cobrar el vehículo con placa ${ticket['placa']}? Utiliza esto si el escaneo OCR falla.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cobrar Vehículo'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      _procesarSalidaManual(context, ref, ticket['id']);
    }
  }

  Future<void> _procesarSalidaManual(BuildContext context, WidgetRef ref, int ticketId) async {
    try {
      final repo = ref.read(ticketRepositoryProvider);
      final horaVerdadera = ref.read(timeManagerProvider.notifier).getTrueTime();

      final resultado = await repo.registrarSalida(
        ticketId: ticketId,
        fechaSalida: horaVerdadera,
        tarifaActual: 1.0, 
        cortesiaActual: 3,
      );

      // Invalida el provider para que la lista se recargue automáticamente
      ref.invalidate(activeTicketsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cobro exitoso: \$${resultado['costo']}'),
            backgroundColor: Theme.of(context).colorScheme.success, // Usando tu extensión de tema
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos la base de datos
    final activeTicketsAsync = ref.watch(activeTicketsProvider);
    final horaActualBlindada = ref.watch(timeManagerProvider.notifier).getTrueTime();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículos Activos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeTicketsProvider),
          )
        ],
      ),
      body: activeTicketsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: AppSkeleton(height: 80), // Tu skeleton en acción
          ),
        ),
        error: (error, stack) => Center(
          child: Text('Error al cargar datos: $error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(height: 16),
                  Text('No hay vehículos en el parqueo', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final tiempoTranscurrido = _calcularTiempo(ticket['entrada'] as String, horaActualBlindada);
              
              return AppActiveVehicleCard(
                placa: ticket['placa'] as String,
                tiempo: tiempoTranscurrido,
                isSyncPending: ticket['sincronizado'] == 0,
                onCobrar: () => _mostrarConfirmacionCobro(context, ref, ticket), // El diálogo intacto
              );
            },
          );
        },
      ),
    );
  }
}