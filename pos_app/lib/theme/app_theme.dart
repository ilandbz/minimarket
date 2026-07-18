import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales (Premium Indigo & Emerald)
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF3730A3); // Indigo 800
  static const Color accent = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500

  // Fondo Oscuro Premium
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkText = Color(0xFFF8FAFC); // Slate 50

  // Fondo Claro Premium
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF0F172A); // Slate 900

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF6366F1)], // Indigo 600 a Indigo 500
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFF34D399)], // Emerald 500 a Emerald 400
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkBackground, darkSurface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Tema Claro
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        error: error,
        surface: lightSurface,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Tema Oscuro
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        error: error,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
