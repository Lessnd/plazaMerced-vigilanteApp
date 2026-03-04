import 'package:flutter/material.dart';

extension CustomColorScheme on ColorScheme {
  Color get success => const Color(0xFF2E7D32); 
  Color get onSuccess => Colors.white;
  Color get warning => const Color(0xFFED6C02); 
  Color get onWarning => Colors.white;
}

class AppTheme {
  static ThemeData get lightTheme {
    // Colores para el SoftUI Táctico
    const Color primaryColor = Color(0xFF4A90E2); // Un azul más suave y moderno
    const Color scaffoldBackground = Color(0xFFEEF2F6); // Gris azulado, la base del SoftUI
    const Color surfaceColor = Colors.white; 

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        background: scaffoldBackground,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: scaffoldBackground, 
      
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBackground, // Appbar se funde con el fondo (Look SoftUI)
        foregroundColor: Color(0xFF2C3E50), // Texto oscuro para contraste
        elevation: 0, // Sin sombra dura en el header
        centerTitle: false,
      ),

      // ✅ Tarjetas con estética SoftUI (Acolchadas y flotantes)
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 8, // Elevación alta pero con sombra muy suave
        shadowColor: const Color(0xFF9EABBA).withOpacity(0.3), // Sombra gris azulada difusa
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Bordes muy redondeados (Soft)
          side: BorderSide.none, // Quitamos las líneas duras
        ),
        margin: EdgeInsets.zero, 
      ),

      // ✅ Campos de texto acolchados
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor, 
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // Sin bordes duros
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFFBDC3C7)),
      ),

      // ✅ Botones redondeados y amigables
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}