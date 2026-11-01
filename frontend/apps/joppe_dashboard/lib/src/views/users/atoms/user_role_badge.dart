import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: Role badge component displaying role name and icon with role-specific styling.
class UserRoleBadge extends StatelessWidget {
  final String roleName;

  const UserRoleBadge({super.key, required this.roleName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final r = roleName.toUpperCase();

    Color bgColor;
    Color fgColor;
    IconData icon;

    if (r.contains('ADMIN')) {
      bgColor = cs.primaryContainer;
      fgColor = cs.onPrimaryContainer;
      icon = Icons.security_rounded;
    } else if (r.contains('STAFF')) {
      bgColor = Colors.teal.shade50;
      fgColor = Colors.teal.shade800;
      icon = Icons.badge_outlined;
    } else {
      bgColor = cs.surfaceContainerHighest;
      fgColor = cs.onSurfaceVariant;
      icon = Icons.person_outline_rounded;
    }

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
          Icon(icon, size: 13, color: fgColor),
          const SizedBox(width: 4),
          Text(
            l10n.userRoleLabel(roleName),
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
