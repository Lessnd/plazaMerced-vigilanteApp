import 'package:flutter/material.dart';
import 'app_skeleton.dart';

class AppVehicleCard extends StatelessWidget {
  final String placa;
  final String tiempo;
  final String? monto; // Null si sigue activo
  final bool isSyncPending;
  final VoidCallback? onTap;
  final bool isLoading; // Para cuando se esté cargando la lista

  const AppVehicleCard({
    super.key,
    required this.placa,
    required this.tiempo,
    this.monto,
    this.isSyncPending = false,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12.0),
        child: AppSkeleton(height: 80),
      );
    }

    final theme = Theme.of(context);
    final isClosed = monto != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isClosed ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.directions_car,
            color: isClosed ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          placa,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Tiempo: $tiempo'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (monto != null)
              Text(
                monto!,
                style: TextStyle(
                  color: theme.colorScheme.error, // Usamos tu color para cobros
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            if (isSyncPending)
              const Icon(Icons.cloud_off, size: 16, color: Colors.orange),
          ],
        ),
      ),
    );
  }
}