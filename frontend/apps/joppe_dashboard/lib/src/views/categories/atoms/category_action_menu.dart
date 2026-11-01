import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: Three-dot dropdown menu providing row-level actions for a category:
/// Add Subcategory, Edit, Toggle Active Status, and Delete.
class CategoryActionMenu extends StatelessWidget {
  final int categoryId;
  final String categoryName;
  final bool isActive;
  final ValueChanged<int> onAddSubcategory;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const CategoryActionMenu({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.isActive,
    required this.onAddSubcategory,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      tooltip: l10n.actionCol,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(JoppeShapes.small),
        side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
      ),
      onSelected: (action) {
        switch (action) {
          case 'add_sub':
            onAddSubcategory(categoryId);
            break;
          case 'edit':
            onEdit();
            break;
          case 'toggle_status':
            onToggleStatus();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'add_sub',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: cs.primary),
              const SizedBox(width: JoppeSpacing.sm),
              Text(l10n.addSubcategoryTooltip, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: JoppeSpacing.sm),
              Text(l10n.editCategoryTooltip, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle_status',
          child: Row(
            children: [
              Icon(
                isActive ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
                size: 20,
                color: isActive ? Colors.green.shade700 : cs.onSurfaceVariant,
              ),
              const SizedBox(width: JoppeSpacing.sm),
              Text(
                isActive ? l10n.deactivateCategory : l10n.activateCategory,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: cs.error),
              const SizedBox(width: JoppeSpacing.sm),
              Text(
                l10n.deleteCategoryTooltip,
                style: TextStyle(fontSize: 13, color: cs.error, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
