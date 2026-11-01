import 'package:flutter/material.dart';
import '../localization/dashboard_localizations.dart';

class ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const ThemeModeSelector({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    final IconData icon;
    final String label;
    switch (currentThemeMode) {
      case ThemeMode.light:
        icon = Icons.light_mode_outlined;
        label = l10n.themeLight;
        break;
      case ThemeMode.dark:
        icon = Icons.dark_mode_outlined;
        label = l10n.themeDark;
        break;
      case ThemeMode.system:
        icon = Icons.brightness_auto_outlined;
        label = l10n.themeSystem;
        break;
    }

    return PopupMenuButton<ThemeMode>(
      tooltip: l10n.themeMode,
      initialValue: currentThemeMode,
      offset: const Offset(0, 42),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      color: colorScheme.surface,
      itemBuilder: (context) => [
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(
                Icons.light_mode_outlined,
                size: 18,
                color: currentThemeMode == ThemeMode.light ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.themeLight,
                  style: TextStyle(
                    fontWeight: currentThemeMode == ThemeMode.light ? FontWeight.bold : FontWeight.normal,
                    color: currentThemeMode == ThemeMode.light ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ),
              if (currentThemeMode == ThemeMode.light)
                Icon(Icons.check, size: 18, color: colorScheme.primary),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(
                Icons.dark_mode_outlined,
                size: 18,
                color: currentThemeMode == ThemeMode.dark ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.themeDark,
                  style: TextStyle(
                    fontWeight: currentThemeMode == ThemeMode.dark ? FontWeight.bold : FontWeight.normal,
                    color: currentThemeMode == ThemeMode.dark ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ),
              if (currentThemeMode == ThemeMode.dark)
                Icon(Icons.check, size: 18, color: colorScheme.primary),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(
                Icons.brightness_auto_outlined,
                size: 18,
                color: currentThemeMode == ThemeMode.system ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.themeSystem,
                  style: TextStyle(
                    fontWeight: currentThemeMode == ThemeMode.system ? FontWeight.bold : FontWeight.normal,
                    color: currentThemeMode == ThemeMode.system ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
              ),
              if (currentThemeMode == ThemeMode.system)
                Icon(Icons.check, size: 18, color: colorScheme.primary),
            ],
          ),
        ),
      ],
      onSelected: onThemeModeChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(70),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(90)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
