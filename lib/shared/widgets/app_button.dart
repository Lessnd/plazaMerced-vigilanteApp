import 'package:flutter/material.dart';

enum AppButtonType { primary, secondary, error }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonType type;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.type = AppButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determinamos el color basado en el tipo, o dejamos que el tema decida
    Color? backgroundColor;
    Color? foregroundColor;

    if (type == AppButtonType.error) {
      backgroundColor = colorScheme.error;
      foregroundColor = colorScheme.onError;
    } else if (type == AppButtonType.secondary) {
      backgroundColor = colorScheme.secondary;
      foregroundColor = colorScheme.onSecondary;
    }

    // Estilo dinámico que sobreescribe solo si es necesario
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      // El padding y el radio ya vienen heredados del AppTheme
    );

    final child = isLoading
        ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity, // Ocupa todo el ancho por defecto
      child: FilledButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}