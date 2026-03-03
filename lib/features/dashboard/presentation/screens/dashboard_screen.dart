import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigilante_app/core/theme/app_theme.dart';

// Servicios y Utilidades
import '../../../../core/services/ocr_service.dart';
import '../../../../core/utils/time_manager.dart';
import '../../../../core/services/device_service.dart';
import '../../../../core/sync/connectivity_service.dart';
import '../../../../core/sync/sync_provider.dart';

// Repositorios y Providers de Features
import '../../../parking/data/repositories/ticket_repository_impl.dart';
import '../../../parking/presentation/providers/active_ticket_provider.dart';
import '../../../parking/presentation/providers/history_tickets_provider.dart';
import '../../../config/presentation/providers/config_provider.dart';
import '../../../banos/data/banos_repository.dart';

// Widgets Compartidos
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_toast.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isProcessing = false;
  final TextEditingController _placaEntradaController = TextEditingController();
  final TextEditingController _placaSalidaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(timeManagerProvider.notifier).syncTimeWithNTP();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AsyncValue<void>>(syncProvider, (previous, next) {
        if (next.hasError) {
          AppToastService.show(context, next.error.toString(), type: AppToastType.error);
        } else if (next.hasValue && !next.isLoading) {
          AppToastService.show(context, 'Sincronización completada con éxito', type: AppToastType.success);
        }
      });
    });
  }

  @override
  void dispose() {
    _placaEntradaController.dispose();
    _placaSalidaController.dispose();
    super.dispose();
  }

  Future<bool> _checkConnectivity() async {
    final connectivity = ref.read(connectivityServiceProvider);
    final isConnected = await connectivity.isConnected;
    if (!isConnected && mounted) {
      AppToastService.show(
        context,
        'Sin conexión a internet. Los datos se guardarán localmente.',
        type: AppToastType.warning,
      );
      print('⚠️ [Dashboard] Operación sin internet - modo offline');
    }
    return isConnected;
  }

  // --- LÓGICA DE OCR NORMALIZADA ---
  Future<void> _handleOcrEntrada() async {
    if (_isProcessing) return;
    try {
      final plate = await OcrService.captureAndRecognize(context, useCloud: true, region: 'sv');
      if (plate != null && plate.isNotEmpty && mounted) {
        // Blindaje contra espacios inyectados por la cámara
        final placaLimpia = plate.toUpperCase().replaceAll(' ', '');
        setState(() => _placaEntradaController.text = placaLimpia);
      }
    } catch (e) {
      if (mounted) AppToastService.show(context, 'Error al escanear placa', type: AppToastType.error);
    }
  }

  Future<void> _handleOcrSalida() async {
    if (_isProcessing) return;
    try {
      final plate = await OcrService.captureAndRecognize(context, useCloud: true, region: 'sv');
      if (plate != null && plate.isNotEmpty && mounted) {
        final placaLimpia = plate.toUpperCase().replaceAll(' ', '');
        setState(() => _placaSalidaController.text = placaLimpia);
      }
    } catch (e) {
      if (mounted) AppToastService.show(context, 'Error al escanear placa', type: AppToastType.error);
    }
  }

  // --- LÓGICA DE BAÑOS ---
  Future<void> _handleCobroBano() async {
    final config = await ref.read(currentConfigProvider.future);
    final tarifaBano = (config['tarifaBano'] as num?)?.toDouble() ?? 0.25; 

    if (!mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cobro de Baño'),
        content: Text('¿Registrar ingreso al baño por \$${tarifaBano.toStringAsFixed(2)}?', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar Cobro'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(banosRepositoryProvider);
      final deviceId = await ref.read(deviceServiceProvider).getDeviceId();
      final horaVerdadera = ref.read(timeManagerProvider.notifier).getTrueTime();

      await repo.registrarUsoBano(
        tarifaCobrada: tarifaBano,
        fechaUso: horaVerdadera.toIso8601String(),
        deviceId: deviceId,
      );

      if (mounted) {
        AppToastService.show(context, 'Cobro de baño registrado: \$${tarifaBano.toStringAsFixed(2)}', type: AppToastType.success);
      }
    } catch (e) {
      if (mounted) AppToastService.show(context, 'Error al registrar baño: $e', type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- LÓGICA DE ENTRADA DE VEHÍCULOS ---
  Future<void> _handleEntrada() async {
    final placa = _placaEntradaController.text.trim();
    if (placa.isEmpty) {
      if (mounted) AppToastService.show(context, 'La placa es obligatoria.', type: AppToastType.error);
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _checkConnectivity();

      final deviceId = await ref.read(deviceServiceProvider).getDeviceId();
      final repo = ref.read(ticketRepositoryProvider);
      final horaVerdadera = ref.read(timeManagerProvider.notifier).getTrueTime();

      // Lectura REAL de la base de datos
      final config = await ref.read(currentConfigProvider.future);
      final tarifaActual = (config['tarifaParqueoHora'] as num?)?.toDouble() ?? 1.0;

      final ticket = await repo.registrarEntrada(
        placa: placa,
        deviceId: deviceId,
        fechaEntrada: horaVerdadera,
        tarifaAplicada: tarifaActual,
      );

      if (mounted) {
        AppToastService.show(context, 'Entrada exitosa: $placa (Ticket ${ticket.id})', type: AppToastType.success);
        _placaEntradaController.clear();
        FocusScope.of(context).unfocus();
        ref.invalidate(activeTicketsProvider);
      }
    } catch (e) {
      if (mounted) AppToastService.show(context, 'Error: $e', type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- LÓGICA DE SALIDA DE VEHÍCULOS ---
  Future<void> _handleSalidaPorPlaca() async {
    final placaBusqueda = _placaSalidaController.text.trim();
    if (placaBusqueda.isEmpty) {
      if (mounted) AppToastService.show(context, 'Ingresa o escanea la placa.', type: AppToastType.error);
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _checkConnectivity(); 

      final repo = ref.read(ticketRepositoryProvider);
      final allTickets = await repo.obtenerTodosLosTickets();
      final ticketMatch = allTickets.where((t) => t.salida == null && t.placa == placaBusqueda).toList();

      if (ticketMatch.isEmpty) {
        if (mounted) AppToastService.show(context, 'No se encontró vehículo activo con la placa $placaBusqueda.', type: AppToastType.warning);
        setState(() => _isProcessing = false);
        return;
      }

      final ticketActivo = ticketMatch.first;
      final horaVerdadera = ref.read(timeManagerProvider.notifier).getTrueTime();

      // Lectura REAL de la base de datos
      final config = await ref.read(currentConfigProvider.future);
      final double tarifaActual = (config['tarifaParqueoHora'] as num?)?.toDouble() ?? 1.0;
      // Asumiendo que minutos_cortesia se agregará a tu DB, sino usamos el fallback
      final int cortesiaActual = (config['minutos_cortesia'] as num?)?.toInt() ?? 3; 

      final ticketCerrado = await repo.registrarSalida(
        ticketId: ticketActivo.id!,
        fechaSalida: horaVerdadera,
        tarifaActual: tarifaActual,
        cortesiaActual: cortesiaActual,
      );

      final minutosTotales = ticketCerrado.salida!.difference(ticketCerrado.entrada).inMinutes;

      if (mounted) {
        AppToastService.show(context, 'Cobro exitoso: \$${ticketCerrado.costo?.toStringAsFixed(2)} ($minutosTotales min) - Placa: $placaBusqueda', type: AppToastType.success);
        _placaSalidaController.clear();
        FocusScope.of(context).unfocus();
        
        ref.invalidate(activeTicketsProvider); 
        ref.invalidate(historyTicketsProvider); 
      }
    } catch (e) {
      if (mounted) AppToastService.show(context, 'Error: $e', type: AppToastType.error);
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
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operación', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: syncState.isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            onPressed: syncState.isLoading ? null : () => ref.refresh(syncProvider),
          ),
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
                      suffixIcon: IconButton(icon: const Icon(Icons.camera_alt), color: colorScheme.primary, onPressed: _handleOcrEntrada),
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
                      suffixIcon: IconButton(icon: const Icon(Icons.camera_alt), color: colorScheme.error, onPressed: _handleOcrSalida),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Cobrar Vehículo',
                      icon: Icons.logout,
                      type: AppButtonType.error,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canOperate ? _handleCobroBano : null,
        icon: const Icon(Icons.wc),
        label: const Text('Baño', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.tertiaryContainer,
        foregroundColor: theme.colorScheme.onTertiaryContainer,
      ),
    );
  }
}