import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_manager.dart';
import '../../../parking/data/repositories/ticket_repository_impl.dart';
import '../../../../core/services/device_service.dart';
import 'package:vigilante_app/features/parking/presentation/providers/active_ticket_provider.dart';

import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isProcessing = false;
  
  // Controlador para la ENTRADA
  final TextEditingController _placaEntradaController = TextEditingController();
  // Controlador para la SALIDA
  final TextEditingController _placaSalidaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(timeManagerProvider.notifier).syncTimeWithNTP();
    });
  }

  @override
  void dispose() {
    _placaEntradaController.dispose();
    _placaSalidaController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color backgroundColor, Color textColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
      ),
    );
  }

  // --- LÓGICA DE ENTRADA ---
  Future<void> _handleEntrada() async {
    final placa = _placaEntradaController.text.trim();
    
    if (placa.isEmpty) {
      _showSnackBar('La placa es obligatoria para registrar entrada.', Theme.of(context).colorScheme.error, Theme.of(context).colorScheme.onError);
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final deviceId = await ref.read(deviceServiceProvider).getDeviceId();
      final repo = ref.read(ticketRepositoryProvider);
      final horaVerdadera = ref.read(timeManagerProvider.notifier).getTrueTime();
      
      final idInsertado = await repo.registrarEntrada(placa: placa, deviceId: deviceId, fechaEntrada: horaVerdadera);

      if (mounted) {
        _showSnackBar('Entrada exitosa: $placa (Ticket $idInsertado)', Theme.of(context).colorScheme.success, Theme.of(context).colorScheme.onSuccess);
        _placaEntradaController.clear();
        FocusScope.of(context).unfocus();
        
        // 🔄 Actualizamos la lista de activos en segundo plano
        ref.invalidate(activeTicketsProvider);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', Theme.of(context).colorScheme.error, Theme.of(context).colorScheme.onError);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- NUEVA LÓGICA DE SALIDA BLINDADA ---
  Future<void> _handleSalidaPorPlaca() async {
    final placaBusqueda = _placaSalidaController.text.trim();

    if (placaBusqueda.isEmpty) {
      _showSnackBar('Ingresa o escanea la placa para cobrar.', Theme.of(context).colorScheme.error, Theme.of(context).colorScheme.onError);
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(ticketRepositoryProvider);
      final allTickets = await repo.obtenerTodosLosTicketsCrudos();
      
      // Buscamos si existe un vehículo con esa placa que NO haya salido aún
      final ticketMatch = allTickets.where((t) => t['salida'] == null && t['placa'] == placaBusqueda).toList();

      if (ticketMatch.isEmpty) {
        if (mounted) {
          _showSnackBar('No se encontró vehículo activo con la placa $placaBusqueda.', Theme.of(context).colorScheme.warning, Theme.of(context).colorScheme.onWarning);
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Si lo encuentra, extraemos su ID y cobramos
      final idCobrar = ticketMatch.first['id'] as int;
      final horaVerdadera = ref.read(timeManagerProvider.notifier).getTrueTime();

      final resultado = await repo.registrarSalida(
        ticketId: idCobrar,
        fechaSalida: horaVerdadera,
        tarifaActual: 1.0, // ESTO DEBERÍA VENIR DE CONFIGURACIÓN LUEGO
        cortesiaActual: 3,
      );

      if (mounted) {
        _showSnackBar(
          'Cobro exitoso: \$${resultado['costo']} (${resultado['minutos_totales']} min) - Placa: $placaBusqueda',
          Theme.of(context).colorScheme.success,
          Theme.of(context).colorScheme.onSuccess,
        );
        _placaSalidaController.clear();
        FocusScope.of(context).unfocus();
        
        // 🔄 Invalidamos para que desaparezca de la pestaña de activos
        ref.invalidate(activeTicketsProvider);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error en cobro: $e', Theme.of(context).colorScheme.error, Theme.of(context).colorScheme.onError);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeState = ref.watch(timeManagerProvider);
    final bool canOperate = timeState.hasValue && !_isProcessing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operación', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: timeState.when(
              data: (_) => Icon(Icons.security, color: colorScheme.success),
              loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => Icon(Icons.warning_amber_rounded, color: colorScheme.error),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- MÓDULO DE ENTRADA ---
            Text('Registro de Entrada', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    AppTextField(
                      controller: _placaEntradaController,
                      label: 'Número de Placa',
                      hint: 'Ej: P123456',
                      prefixIcon: Icons.login,
                      isRequired: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        color: colorScheme.primary,
                        onPressed: () {
                          _showSnackBar('OCR Entrada pendiente', colorScheme.secondary, colorScheme.onSecondary);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Registrar Entrada',
                      icon: Icons.check_circle_outline,
                      isLoading: _isProcessing && _placaEntradaController.text.isNotEmpty,
                      onPressed: canOperate ? _handleEntrada : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- MÓDULO DE SALIDA ---
            Text('Cobro y Salida', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _placaSalidaController,
                      label: 'Buscar Placa para Salida',
                      hint: 'Ej: P123456',
                      prefixIcon: Icons.search,
                      isRequired: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        color: colorScheme.error, // Usamos rojo para alertar que esto involucra dinero
                        onPressed: () {
                          _showSnackBar('OCR Salida pendiente', colorScheme.secondary, colorScheme.onSecondary);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Cobrar Vehículo',
                      icon: Icons.logout,
                      type: AppButtonType.error, // Botón rojo para salida
                      isLoading: _isProcessing && _placaSalidaController.text.isNotEmpty,
                      onPressed: canOperate ? _handleSalidaPorPlaca : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}