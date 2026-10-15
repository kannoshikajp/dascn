import 'package:flutter/material.dart';

/// Joppe Google Material 3 color palettes and brand seeds.
class JoppeColors {
  JoppeColors._();

  // Core brand seed colors
  static const Color primarySeed = Color(0xFF1E40AF); // Deep Tech Blue
  static const Color secondarySeed = Color(0xFF0284C7); // Vibrant Cyan/Sky
  static const Color tertiarySeed = Color(0xFFF97316); // High-contrast Tech Amber
  static const Color neutralSeed = Color(0xFF64748B); // Slate neutral

  // Functional semantic colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFCA8A04);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  /// Light ColorScheme based on M3 algorithmic tonal palettes
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: primarySeed,
    brightness: Brightness.light,
    primary: const Color(0xFF1E40AF),
    secondary: const Color(0xFF0284C7),
    tertiary: const Color(0xFFF97316),
    surface: const Color(0xFFF8FAFC),
  );

  /// Dark ColorScheme based on M3 algorithmic tonal palettes
  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: primarySeed,
    brightness: Brightness.dark,
    primary: const Color(0xFF93C5FD),
    secondary: const Color(0xFF7DD3FC),
    tertiary: const Color(0xFFFDBA74),
    surface: const Color(0xFF0F172A),
  );
}
