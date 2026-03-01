import 'package:flutter/material.dart';
import 'package:vigilante_app/core/theme/app_theme.dart';

/// Tipos de notificación soportados
enum AppToastType { success, error, warning, info }

/// Widget de notificación flotante no intrusiva.
/// Debe ser insertado en un [Overlay] para mostrarse.
class AppToast extends StatefulWidget {
  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback? onDismiss;

  const AppToast({
    super.key,
    required this.message,
    this.type = AppToastType.info,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<AppToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // desde arriba
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // Iniciar animación de entrada
    _controller.forward();

    // Programar auto-cierre
    Future.delayed(widget.duration, () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.type) {
      case AppToastType.success:
        return colorScheme.success;
      case AppToastType.error:
        return colorScheme.error;
      case AppToastType.warning:
        return colorScheme.warning;
      case AppToastType.info:
        return colorScheme.secondary;
    }
  }

  Color _getTextColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (widget.type) {
      case AppToastType.success:
        return colorScheme.onSuccess;
      case AppToastType.error:
        return colorScheme.onError;
      case AppToastType.warning:
        return colorScheme.onWarning;
      case AppToastType.info:
        return colorScheme.onSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: GestureDetector(
                  onTap: _dismiss, // Cerrar al tocar
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                    ), // ancho máximo en tablets
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(context),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIcon(),
                          color: _getTextColor(context),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: _getTextColor(context),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.type) {
      case AppToastType.success:
        return Icons.check_circle_outline;
      case AppToastType.error:
        return Icons.error_outline;
      case AppToastType.warning:
        return Icons.warning_amber_outlined;
      case AppToastType.info:
        return Icons.info_outline;
    }
  }
}

/// Servicio para mostrar notificaciones de manera fácil.
/// Uso: AppToastService.show(context, mensaje, tipo);
class AppToastService {
  static OverlayEntry? _currentToast;

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration? duration,
  }) {
    // Eliminar el toast anterior si existe
    _currentToast?.remove();

    // Crear nuevo overlay
    _currentToast = OverlayEntry(
      builder: (context) => AppToast(
        message: message,
        type: type,
        duration: duration ?? const Duration(seconds: 3),
        onDismiss: () {
          _currentToast?.remove();
          _currentToast = null;
        },
      ),
    );

    // Insertar en el overlay
    Overlay.of(context).insert(_currentToast!);
  }
}
