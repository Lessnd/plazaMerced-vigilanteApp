import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/parking/domain/models/ticket.dart';
import '../../core/utils/time_manager.dart';
import '../../features/config/presentation/providers/config_provider.dart';

class AppActiveVehicleCard extends ConsumerWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const AppActiveVehicleCard({
    super.key,
    required this.ticket,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. Escuchamos el provider solo para reaccionar al 'tick' y actualizar la tarjeta cada minuto
    ref.watch(timeManagerProvider);
    
    // 2. Extraemos el objeto DateTime real directamente del Notifier
    final DateTime now = ref.read(timeManagerProvider.notifier).getTrueTime();

    final configAsync = ref.watch(currentConfigProvider);
    final tarifa = (configAsync.valueOrNull?['tarifaParqueoHora'] as num?)?.toDouble() ?? 1.0;
    final cortesia = (configAsync.valueOrNull?['minutos_cortesia'] as num?)?.toInt() ?? 3;

    // ✅ BLINDAJE EMPRESARIAL: Si el cálculo falla, la UI sobrevive
    int horas = 0;
    int minutosRestantes = 0;
    double costoCalculado = 0.0;

    try {
      final duracion = now.difference(ticket.entrada);
      final minutosTotales = duracion.inMinutes < 0 ? 0 : duracion.inMinutes; 
      
      horas = duracion.inHours;
      minutosRestantes = minutosTotales % 60;

      if (minutosTotales > cortesia) {
        final horasACobrar = (minutosTotales / 60).ceil();
        costoCalculado = horasACobrar * tarifa;
      }
    } catch (e) {
      print('⚠️ [AppActiveVehicleCard] Error crítico evitado en UI: $e');
      // La tarjeta mostrará 0h 0m y $0.00 en lugar de crashear la app.
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap, 
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.directions_car, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        ticket.placa,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ACTIVO',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIEMPO DE ESTADÍA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${horas}h ${minutosRestantes}m',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'COBRO ESTIMADO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${costoCalculado.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}