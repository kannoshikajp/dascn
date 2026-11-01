import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

/// Atom: Visual and interactive pill representing a permission item.
class PermissionPill extends StatelessWidget {
  final String permissionName;
  final String? description;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final bool compact;

  const PermissionPill({
    super.key,
    required this.permissionName,
    this.description,
    this.isSelected = false,
    this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (onSelected != null) {
      return FilterChip(
        selected: isSelected,
        onSelected: onSelected,
        showCheckmark: true,
        tooltip: description,
        avatar: isSelected
            ? null
            : Icon(Icons.circle_outlined, size: 12, color: cs.onSurfaceVariant.withAlpha(150)),
        label: Text(
          permissionName,
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
          ),
        ),
        selectedColor: cs.primaryContainer,
        backgroundColor: cs.surfaceContainerHighest.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(JoppeShapes.small),
          side: BorderSide(
            color: isSelected ? cs.primary.withAlpha(120) : cs.outlineVariant.withAlpha(80),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }

    // Static display badge
    return Tooltip(
      message: description ?? permissionName,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(JoppeShapes.small),
          border: Border.all(color: cs.outlineVariant.withAlpha(90)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: cs.primary),
            const SizedBox(width: JoppeSpacing.xs),
            Flexible(
              child: Text(
                permissionName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
