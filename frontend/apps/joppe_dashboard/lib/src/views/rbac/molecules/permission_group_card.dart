import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../atoms/permission_pill.dart';
import '../utils/rbac_category_helper.dart';

/// Molecule: Group of permissions belonging to one category/type displayed as pills.
class PermissionGroupCard extends StatelessWidget {
  final String groupKey;
  final List<PermissionItem> permissions;
  final Set<String> selectedPermissions;
  final ValueChanged<String>? onTogglePermission;
  final bool isEditable;

  const PermissionGroupCard({
    super.key,
    required this.groupKey,
    required this.permissions,
    required this.selectedPermissions,
    this.onTogglePermission,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    final categoryTitle = RbacCategoryHelper.getCategoryTitle(groupKey, isVi: isVi);
    final categoryIcon = RbacCategoryHelper.getCategoryIcon(groupKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: JoppeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Icon + Title
          Row(
            children: [
              Icon(categoryIcon, size: 16, color: cs.primary),
              const SizedBox(width: JoppeSpacing.xs),
              Text(
                categoryTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: JoppeSpacing.xs),

          // Pills Wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: permissions.map((perm) {
              final isSelected = selectedPermissions.contains(perm.permissionName);
              return PermissionPill(
                permissionName: perm.permissionName,
                description: perm.description,
                isSelected: isSelected,
                onSelected: isEditable && onTogglePermission != null
                    ? (_) => onTogglePermission!(perm.permissionName)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
