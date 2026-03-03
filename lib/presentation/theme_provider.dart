import 'package:flutter/material.dart';

/// Define una colección de temas (claro y oscuro) para la aplicación.
///
/// Utiliza los principios de Material 3 para un diseño moderno y adaptable.
class AppTheme {
  /// Tema de la aplicación en modo claro.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green, // Verde para el primario (ahorros)
        brightness: Brightness.light,
        background: Colors.grey.shade50, // Fondo limpio y claro
        surface: Colors.white,
        primary: Colors.green.shade700,
        onPrimary: Colors.white,
        secondary: Colors.teal,
        onSecondary: Colors.white,
        error: Colors.red.shade700,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      // Puedes personalizar más componentes aquí según sea necesario.
    );
  }

  /// Tema de la aplicación en modo oscuro.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal.shade700, // Verde esmeralda para el primario en modo oscuro
        brightness: Brightness.dark,
        background: Colors.grey.shade900, // Fondo gris muy oscuro (no negro puro)
        surface: Colors.grey.shade800,
        primary: Colors.teal.shade700,
        onPrimary: Colors.white,
        secondary: Colors.cyan.shade300,
        onSecondary: Colors.black,
        error: Colors.red.shade400,
        onError: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
        ),
      ),
      // Puedes personalizar más componentes aquí según sea necesario.
    );
  }
}
