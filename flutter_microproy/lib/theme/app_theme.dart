/// Temas visuales del 15-Puzzle: claro, oscuro y conversión del ajuste.
library;

import 'package:flutter/material.dart';

import 'package:flutter_microproy/models/models.dart';

/// Colores y estilos compartidos por todas las pantallas.
abstract final class AppTheme {
  /// Color base del que Material 3 genera toda la paleta.
  static const Color _seed = Color(0xFF6750A4);

  /// Tema claro.
  static ThemeData get light => _build(Brightness.light);

  /// Tema oscuro.
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      appBarTheme: const AppBarTheme(centerTitle: true),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  /// Traduce el ajuste guardado al ThemeMode de Flutter.
  static ThemeMode toThemeMode(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }
}
