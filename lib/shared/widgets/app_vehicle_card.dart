import 'package:flutter/material.dart';
import '../../features/parking/domain/models/ticket.dart';

class AppVehicleCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;

  const AppVehicleCard({
    super.key,
    required this.ticket,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. Cálculos estáticos (La transacción ya ocurrió)
    final duracion = ticket.salida != null ? ticket.salida!.difference(ticket.entrada) : Duration.zero;
    final horas = duracion.inHours;
    final minutosRestantes = duracion.inMinutes % 60;
    final costo = ticket.costo ?? 0.0;

    // 2. Formateo de fechas para auditoría rápida
    final entradaStr = "${ticket.entrada.day.toString().padLeft(2, '0')}/${ticket.entrada.month.toString().padLeft(2, '0')} ${ticket.entrada.hour.toString().padLeft(2, '0')}:${ticket.entrada.minute.toString().padLeft(2, '0')}";
    final salidaStr = ticket.salida != null 
        ? "${ticket.salida!.day.toString().padLeft(2, '0')}/${ticket.salida!.month.toString().padLeft(2, '0')} ${ticket.salida!.hour.toString().padLeft(2, '0')}:${ticket.salida!.minute.toString().padLeft(2, '0')}"
        : "N/A";

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- FILA SUPERIOR: Identificación ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200, // Neutro, ya no está ocupando espacio
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.check_circle, color: Colors.grey.shade600),
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
                  // Badge de Estado (Confirmación Fiscal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.1), // Slate tenue
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'COBRADO',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
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
              
              // --- FILA MEDIA: Sellos de Tiempo ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Entrada: $entradaStr', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('Salida: $salidaStr', style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 16),

              // --- FILA INFERIOR: Analítica Financiera ---
              Row(
                children: [
                  // Bloque Tiempo Total
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TIEMPO TOTAL',
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
                  
                  // Bloque Dinero Ingresado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL COBRADO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${costo.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2E7D32), // Verde dinero (Éxito contable)
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