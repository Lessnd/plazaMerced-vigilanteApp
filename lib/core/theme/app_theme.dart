import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,

      // 🔷 Primary
      primary: Color(0xFF1E3A8A),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE0E7FF),
      onPrimaryContainer: Color(0xFF1E3A8A),

      // ⚙️ Secondary
      secondary: Color(0xFF475569),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF1F5F9),
      onSecondaryContainer: Color(0xFF334155),

      // 🔴 Error
      error: Color(0xFFDC2626),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFFDC2626),

      // 🧱 Surface (Estándar moderno de Material 3)
      surface: Color(0xFFF8FAFC), 
      onSurface: Color(0xFF1E293B), 
      
      surfaceContainerHighest: Color(0xFFF1F5F9), 
      onSurfaceVariant: Color(0xFF334155),

      outline: Color(0xFFCBD5E1),

      // Required but not customized (keep consistent)
      tertiary: Color(0xFF1E3A8A),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE0E7FF),
      onTertiaryContainer: Color(0xFF1E3A8A),

      inverseSurface: Color(0xFF1E293B),
      onInverseSurface: Color(0xFFF8FAFC),
      inversePrimary: Color(0xFFE0E7FF),

      shadow: Colors.black,
      scrim: Colors.black,
      surfaceTint: Color(0xFF1E3A8A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,

      // ✅ CORRECCIÓN 1: Ahora usa 'surface'
      scaffoldBackgroundColor: colorScheme.surface,

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 1,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // ✅ CORRECCIÓN 2: Ahora usa 'surfaceContainerHighest'
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

extension CustomColors on ColorScheme {
  Color get success => const Color(0xFF16A34A);
  Color get successContainer => const Color(0xFFDCFCE7);
  Color get onSuccess => const Color(0xFFFFFFFF);

  Color get warning => const Color(0xFFD97706);
  Color get warningContainer => const Color(0xFFFEF3C7);
  Color get onWarning => const Color(0xFFFFFFFF);
}