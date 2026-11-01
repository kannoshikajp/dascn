import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

enum NotificationType {
  success,
  error,
  info;
}

/// Molecule: Centered notification modal dialog replacing bottom line toasts.
class UserNotificationDialog extends StatelessWidget {
  final String message;
  final String? title;
  final NotificationType type;

  const UserNotificationDialog({
    super.key,
    required this.message,
    this.title,
    this.type = NotificationType.success,
  });

  static Future<void> show({
    required BuildContext context,
    required String message,
    String? title,
    NotificationType type = NotificationType.success,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => UserNotificationDialog(
        message: message,
        title: title,
        type: type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    Color iconBg;
    Color iconFg;
    IconData icon;
    String defaultTitle;

    switch (type) {
      case NotificationType.error:
        iconBg = cs.errorContainer.withAlpha(90);
        iconFg = cs.error;
        icon = Icons.error_outline_rounded;
        defaultTitle = l10n.errorTitle;
        break;
      case NotificationType.info:
        iconBg = cs.primaryContainer.withAlpha(90);
        iconFg = cs.primary;
        icon = Icons.info_outline_rounded;
        defaultTitle = l10n.notificationTitle;
        break;
      case NotificationType.success:
        iconBg = Colors.green.shade50;
        iconFg = Colors.green.shade700;
        icon = Icons.check_circle_outline_rounded;
        defaultTitle = l10n.successTitle;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(JoppeShapes.large)),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconFg, size: 28),
              ),
              const SizedBox(height: JoppeSpacing.md),
              Text(
                title ?? defaultTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: JoppeSpacing.sm),
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: JoppeSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(JoppeShapes.small),
                    ),
                  ),
                  child: Text(l10n.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
