import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigilante_app/core/services/ocr_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_manager.dart';
import '../../../parking/data/repositories/ticket_repository_impl.dart';
import '../../../../core/services/device_service.dart';
import '../../../../core/sync/connectivity_service.dart';
import '../../../../core/sync/sync_provider.dart';
import 'package:vigilante_app/features/parking/presentation/providers/active_ticket_provider.dart';
import 'package:vigilante_app/features/parking/presentation/providers/config_provider.dart'; // ✅ Importado

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
      // Escuchar cambios en el provider de sincronización
      ref.listen<AsyncValue<void>>(syncNowProvider, (previous, next) {
        if (next.hasError) {
          AppToastService.show(
            context,
            next.error.toString(),
            type: AppToastType.error,
          );
        } else if (next.hasValue && !next.isLoading) {
          AppToastService.show(
            context,
            'Sincronización completada con éxito',
            type: AppToastType.success,
          );
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

  // ✅ Obtener tarifa y cortesía de la configuración (valores por defecto si no hay)
  (double tarifa, int cortesia) _obtenerTarifaYCortesia() {
    final configAsync = ref.read(configuracionProvider);
    final config = configAsync.valueOrNull;
    final tarifa = config?.tarifaParqueoHora ?? 1.0;
    const cortesia = 3; // Puede venir de configuración en el futuro
    return (tarifa, cortesia);
  }

  // ✅ NUEVO: Método para manejar OCR de entrada
  Future<void> _handleOcrEntrada() async {
    if (_isProcessing) return;

    try {
      final plate = await OcrService.captureAndRecognize(
        context,
        useCloud: true,
        region: 'mx', // Ajusta según tu país
      );

      if (plate != null && mounted) {
        setState(() {
          _placaEntradaController.text = plate;
        });
      }
    } catch (e) {
      print('❌ [Dashboard] Error en OCR entrada: $e');
      if (mounted) {
        AppToastService.show(
          context,
          'Error al escanear placa',
          type: AppToastType.error,
        );
      }
    }
  }

  // ✅ NUEVO: Método para manejar OCR de salida
  Future<void> _handleOcrSalida() async {
    if (_isProcessing) return;

    try {
      final plate = await OcrService.captureAndRecognize(
        context,
        useCloud: true,
        region: 'mx', // Ajusta según tu país
      );

      if (plate != null && mounted) {
        setState(() {
          _placaSalidaController.text = plate;
        });
      }
    } catch (e) {
      print('❌ [Dashboard] Error en OCR salida: $e');
      if (mounted) {
        AppToastService.show(
          context,
          'Error al escanear placa',
          type: AppToastType.error,
        );
      }
    }
  }

  Future<void> _handleEntrada() async {
    final placa = _placaEntradaController.text.trim();

    if (placa.isEmpty) {
      if (mounted) {
        AppToastService.show(
          context,
          'La placa es obligatoria.',
          type: AppToastType.error,
        );
      }
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _checkConnectivity();

      final deviceId = await ref.read(deviceServiceProvider).getDeviceId();
      final repo = ref.read(ticketRepositoryProvider);
      final horaVerdadera = ref
          .read(timeManagerProvider.notifier)
          .getTrueTime();

      final (tarifaActual, _) = _obtenerTarifaYCortesia();

      // ✅ registrarEntrada ahora requiere tarifaAplicada y devuelve Ticket
      final ticket = await repo.registrarEntrada(
        placa: placa,
        deviceId: deviceId,
        fechaEntrada: horaVerdadera,
        tarifaAplicada: tarifaActual,
      );

      if (mounted) {
        AppToastService.show(
          context,
          'Entrada exitosa: $placa (Ticket ${ticket.id})',
          type: AppToastType.success,
        );
        _placaEntradaController.clear();
        FocusScope.of(context).unfocus();
        ref.invalidate(activeTicketsProvider);
      }
    } catch (e) {
      print('❌ [Dashboard] Error en entrada: $e');
      if (mounted) {
        AppToastService.show(context, 'Error: $e', type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleSalidaPorPlaca() async {
    final placaBusqueda = _placaSalidaController.text.trim();

    if (placaBusqueda.isEmpty) {
      if (mounted) {
        AppToastService.show(
          context,
          'Ingresa o escanea la placa.',
          type: AppToastType.error,
        );
      }
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _checkConnectivity();

      final repo = ref.read(ticketRepositoryProvider);
      // ✅ Cambio: usar obtenerTodosLosTickets() que devuelve List<Ticket>
      final allTickets = await repo.obtenerTodosLosTickets();

      final ticketMatch = allTickets
          .where((t) => t.salida == null && t.placa == placaBusqueda)
          .toList();

      if (ticketMatch.isEmpty) {
        if (mounted) {
          AppToastService.show(
            context,
            'No se encontró vehículo activo con la placa $placaBusqueda.',
            type: AppToastType.warning,
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      final ticketActivo = ticketMatch.first; // ✅ Es Ticket, no Map
      final horaVerdadera = ref
          .read(timeManagerProvider.notifier)
          .getTrueTime();

      final (tarifaActual, cortesiaActual) = _obtenerTarifaYCortesia();

      print(
        '💰 [Dashboard] Usando tarifa: $tarifaActual, cortesía: $cortesiaActual',
      );

      final ticketCerrado = await repo.registrarSalida(
        ticketId: ticketActivo.id!, // ✅ id no es nulo en ticket activo
        fechaSalida: horaVerdadera,
        tarifaActual: tarifaActual,
        cortesiaActual: cortesiaActual,
      );

      final minutosTotales = ticketCerrado.salida!
          .difference(ticketCerrado.entrada)
          .inMinutes;

      if (mounted) {
        AppToastService.show(
          context,
          'Cobro exitoso: \$${ticketCerrado.costo?.toStringAsFixed(2)} ($minutosTotales min) - Placa: $placaBusqueda',
          type: AppToastType.success,
        );
        _placaSalidaController.clear();
        FocusScope.of(context).unfocus();
        ref.invalidate(activeTicketsProvider);
      }
    } catch (e) {
      print('❌ [Dashboard] Error en salida: $e');
      if (mounted) {
        AppToastService.show(context, 'Error: $e', type: AppToastType.error);
      }
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
    final syncState = ref.watch(syncNowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Operación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: syncState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: syncState.isLoading
                ? null
                : () {
                    print('🔄 [Dashboard] Iniciando sincronización manual');
                    ref.refresh(syncNowProvider);
                  },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: timeState.when(
              data: (_) => Icon(Icons.security, color: colorScheme.success),
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) =>
                  Icon(Icons.warning_amber_rounded, color: colorScheme.error),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registro de Entrada',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
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
                        onPressed:
                            _handleOcrEntrada, // ✅ Reemplazado con función real
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Registrar Entrada',
                      icon: Icons.check_circle_outline,
                      isLoading:
                          _isProcessing &&
                          _placaEntradaController.text.isNotEmpty,
                      onPressed: canOperate ? _handleEntrada : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Cobro y Salida',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
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
                        color: colorScheme.error,
                        onPressed:
                            _handleOcrSalida, // ✅ Reemplazado con función real
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Cobrar Vehículo',
                      icon: Icons.logout,
                      type: AppButtonType.error,
                      isLoading:
                          _isProcessing &&
                          _placaSalidaController.text.isNotEmpty,
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
