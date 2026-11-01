import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

class BootLoaderScreen extends StatelessWidget {
  final String baseUrl;

  const BootLoaderScreen({
    super.key,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(JoppeSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 34,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: JoppeSpacing.lg),
                Text(
                  'Joppe Control Center',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: JoppeSpacing.xs),
                Text(
                  'Verifying backend health on /live...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: JoppeSpacing.xl),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: JoppeSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: JoppeSpacing.md,
                    vertical: JoppeSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(JoppeShapes.small),
                  ),
                  child: Text(
                    baseUrl,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
