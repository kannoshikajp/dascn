import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/role_type_badge.dart';
import '../molecules/permission_group_card.dart';
import '../utils/rbac_category_helper.dart';

/// Organism: Detail panel showing selected role info and its assigned permissions grouped by type.
class RoleDetailPanel extends StatelessWidget {
  final RoleItem? role;
  final List<PermissionItem> allPermissions;
  final VoidCallback onEditPermissions;
  final VoidCallback onDeleteRole;

  const RoleDetailPanel({
    super.key,
    required this.role,
    required this.allPermissions,
    required this.onEditPermissions,
    required this.onDeleteRole,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (role == null) {
      return Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(JoppeShapes.medium),
          side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 54, color: cs.onSurfaceVariant.withAlpha(120)),
              const SizedBox(height: JoppeSpacing.sm),
              Text(
                l10n.selectRolePrompt,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final isSystemRole = role!.isSystemRole || role!.roleName == 'ROLE_NON_LOGIN';

    // Map role's permission strings to PermissionItems
    final grantedPermItems = role!.permissions.map((name) {
      return allPermissions.firstWhere(
        (p) => p.permissionName == name,
        orElse: () => PermissionItem(id: 0, permissionName: name),
      );
    }).toList();

    // Group assigned permissions
    final groupedMap = RbacCategoryHelper.groupPermissions(grantedPermItems);
    final grantedSet = Set<String>.from(role!.permissions);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(JoppeShapes.medium),
        side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(JoppeSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: JoppeSpacing.sm,
                        children: [
                          Text(
                            role!.roleName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          RoleTypeBadge(isSystemRole: isSystemRole),
                        ],
                      ),
                      const SizedBox(height: JoppeSpacing.xs),
                      Text(
                        role!.description ?? (isSystemRole ? l10n.systemBuiltinRole : l10n.customRole),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: JoppeSpacing.xs,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: onEditPermissions,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: Text(l10n.editPermissions),
                    ),
                    if (!isSystemRole)
                      IconButton.outlined(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: cs.error,
                        onPressed: onDeleteRole,
                        tooltip: l10n.deleteRole,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: JoppeSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: JoppeSpacing.sm),

            // Section Title
            Row(
              children: [
                Text(
                  l10n.grantedPermissions(role!.permissions.length),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: JoppeSpacing.sm),

            // Grouped Permissions Display
            Expanded(
              child: grantedPermItems.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noPermissionsAssigned,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: groupedMap.keys.length,
                      itemBuilder: (context, index) {
                        final groupKey = groupedMap.keys.elementAt(index);
                        final permsInGroup = groupedMap[groupKey]!;
                        return PermissionGroupCard(
                          groupKey: groupKey,
                          permissions: permsInGroup,
                          selectedPermissions: grantedSet,
                          isEditable: false,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
