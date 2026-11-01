import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: User account status pill displaying active / suspended state.
class UserStatusBadge extends StatelessWidget {
  final bool isActive;

  const UserStatusBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final bgColor = isActive ? Colors.green.shade50 : cs.errorContainer.withAlpha(80);
    final fgColor = isActive ? Colors.green.shade800 : cs.error;
    final label = isActive ? l10n.activeStatus : l10n.suspendedStatus;
    final icon = isActive ? Icons.check_circle_rounded : Icons.block_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(JoppeShapes.small),
        border: Border.all(color: fgColor.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fgColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
