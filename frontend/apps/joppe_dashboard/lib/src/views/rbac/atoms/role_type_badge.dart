import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: Badge visually indicating whether a role is System Protected or Custom.
class RoleTypeBadge extends StatelessWidget {
  final bool isSystemRole;

  const RoleTypeBadge({
    super.key,
    required this.isSystemRole,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final bg = isSystemRole ? cs.secondaryContainer : cs.tertiaryContainer.withAlpha(90);
    final fg = isSystemRole ? cs.onSecondaryContainer : cs.onTertiaryContainer;
    final label = isSystemRole ? l10n.systemProtectedRole : l10n.customRole;
    final icon = isSystemRole ? Icons.shield_outlined : Icons.tune_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(JoppeShapes.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
