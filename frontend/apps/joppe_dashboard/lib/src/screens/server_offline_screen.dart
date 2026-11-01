import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

class ServerOfflineScreen extends StatelessWidget {
  final String baseUrl;
  final String? errorMessage;
  final bool isRetrying;
  final VoidCallback onRetry;

  const ServerOfflineScreen({
    super.key,
    required this.baseUrl,
    this.errorMessage,
    required this.isRetrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JoppeSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(JoppeShapes.large),
                side: BorderSide(
                  color: colorScheme.error.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(JoppeSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_off_rounded,
                          size: 34,
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: JoppeSpacing.lg),
                    Text(
                      'Server Unavailable',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: JoppeSpacing.xs),
                    Text(
                      'Backend service is not live or cannot be reached.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: JoppeSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(JoppeSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(JoppeShapes.medium),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Host:',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: JoppeSpacing.xxs),
                          SelectableText(
                            baseUrl,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: JoppeSpacing.xs),
                          Text(
                            'Liveness Probe Endpoint:',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: JoppeSpacing.xxs),
                          SelectableText(
                            '$baseUrl/live',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: colorScheme.primary,
                            ),
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: JoppeSpacing.xs),
                            Text(
                              'Diagnostics Error:',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: JoppeSpacing.xxs),
                            Text(
                              errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: JoppeSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: JoppeSpacing.md,
                        vertical: JoppeSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(JoppeShapes.small),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_clock_outlined,
                            size: 16,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: JoppeSpacing.xs),
                          Expanded(
                            child: Text(
                              'This screen is locked and cannot be dismissed until /live is reachable.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: JoppeSpacing.xl),
                    FilledButton.icon(
                      onPressed: isRetrying ? null : onRetry,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: JoppeSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(JoppeShapes.medium),
                        ),
                      ),
                      icon: isRetrying
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: Text(
                        isRetrying ? 'Checking /live probe...' : 'Retry Connection',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
