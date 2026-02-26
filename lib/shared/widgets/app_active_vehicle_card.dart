import 'package:flutter/material.dart';

class AppActiveVehicleCard extends StatelessWidget {
  final String placa;
  final String tiempo;
  final bool isSyncPending;
  final VoidCallback onCobrar; // Acción explícita

  const AppActiveVehicleCard({
    super.key,
    required this.placa,
    required this.tiempo,
    this.isSyncPending = false,
    required this.onCobrar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2, // Más elevada para denotar que es accionable
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Borde distintivo primario para separarla del historial
        side: BorderSide(color: colorScheme.primary.withOpacity(0.4), width: 1.5), 
      ),
      child: InkWell(
        onTap: onCobrar, // Aquí se dispara el diálogo de confirmación que ya tienes
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Ícono de vehículo prominente
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.directions_car, color: colorScheme.onPrimaryContainer, size: 28),
              ),
              const SizedBox(width: 16),
              
              // Datos Centrales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placa,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: colorScheme.secondary),
                        const SizedBox(width: 4),
                        Text(
                          tiempo,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Llamado a la acción (Indicador visual de salida)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSyncPending)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 16, color: colorScheme.error),
                        const SizedBox(width: 4),
                        Text(
                          'Cobrar',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
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