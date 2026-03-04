import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool isRequired;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffixIcon,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2, // Espaciado para que las placas sean hiper-legibles
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(prefixIcon, color: theme.colorScheme.primary),
            suffixIcon: suffixIcon,
            // Todo lo demás (bordes, fondo gris, padding) lo inyecta automáticamente el AppTheme
          ),
        ),
      ],
    );
  }
}