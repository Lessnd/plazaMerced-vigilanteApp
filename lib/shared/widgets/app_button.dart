import 'package:flutter/material.dart';

enum AppButtonType { primary, secondary, error }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonType type;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.type = AppButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    Color foregroundColor;

    switch (type) {
      case AppButtonType.error:
        backgroundColor = colorScheme.error;
        foregroundColor = colorScheme.onError;
        break;
      case AppButtonType.secondary:
        backgroundColor = colorScheme.secondary;
        foregroundColor = colorScheme.onSecondary;
        break;
      case AppButtonType.primary:
      default:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
    }

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        // El tamaño mínimo y border radius ya vienen de tu AppTheme
      ),
      onPressed: isLoading ? null : onPressed,
      icon: isLoading 
          ? SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(
                color: foregroundColor, 
                strokeWidth: 2
              )
            )
          : (icon != null ? Icon(icon) : const SizedBox.shrink()),
      label: Text(
        isLoading ? 'Procesando...' : text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}