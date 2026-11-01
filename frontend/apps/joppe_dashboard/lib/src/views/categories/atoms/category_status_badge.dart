import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: Color-coded badge displaying category active/inactive status.
class CategoryStatusBadge extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onToggle;

  const CategoryStatusBadge({
    super.key,
    required this.isActive,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final badgeColor = isActive ? Colors.green.shade700 : Colors.grey.shade600;
    final badgeBg = isActive ? Colors.green.withAlpha(28) : cs.surfaceContainerHigh;
    final text = isActive ? l10n.activeStatusLabel : l10n.inactiveStatusLabel;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(JoppeShapes.small),
        border: Border.all(color: badgeColor.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onToggle != null) {
      return InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(JoppeShapes.small),
        child: badge,
      );
    }

    return badge;
  }
}
