import 'package:flutter/material.dart';
import 'color_schemes.dart';
import 'shapes.dart';

/// Centralized Material 3 ThemeData builder for Joppe applications.
class JoppeTheme {
  JoppeTheme._();

  static ThemeData light() {
    final scheme = JoppeColors.lightScheme;
    return _buildTheme(scheme);
  }

  static ThemeData dark() {
    final scheme = JoppeColors.darkScheme;
    return _buildTheme(scheme);
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 3,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: JoppeShapes.shapeMedium,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: JoppeShapes.shapeSmall,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: JoppeShapes.shapeSmall,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : scheme.surfaceContainerHigh.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(JoppeShapes.small),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(JoppeShapes.small),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(JoppeShapes.small),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 2,
        height: 72,
        indicatorColor: scheme.secondaryContainer,
        backgroundColor: scheme.surfaceContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
      ),
      dialogTheme: DialogThemeData(
        shape: JoppeShapes.shapeExtraLarge,
        backgroundColor: scheme.surfaceContainerHigh,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(
          isDark
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
