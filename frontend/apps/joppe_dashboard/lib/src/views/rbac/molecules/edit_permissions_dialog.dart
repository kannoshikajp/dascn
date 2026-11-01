import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/role_type_badge.dart';
import '../utils/rbac_category_helper.dart';
import 'permission_group_card.dart';

/// Molecule: Modal dialog for editing role permissions using grouped pill lists.
class EditPermissionsDialog extends StatefulWidget {
  final RoleItem role;
  final List<PermissionItem> allPermissions;
  final RbacManagementService rbacService;
  final VoidCallback onPermissionsUpdated;
  final void Function(String message, {bool isError}) notify;

  const EditPermissionsDialog({
    super.key,
    required this.role,
    required this.allPermissions,
    required this.rbacService,
    required this.onPermissionsUpdated,
    required this.notify,
  });

  @override
  State<EditPermissionsDialog> createState() => _EditPermissionsDialogState();
}

class _EditPermissionsDialogState extends State<EditPermissionsDialog> {
  late final Set<String> _selectedPermissions;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedPermissions = Set<String>.from(widget.role.permissions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _togglePermission(String permName) {
    setState(() {
      if (_selectedPermissions.contains(permName)) {
        _selectedPermissions.remove(permName);
      } else {
        _selectedPermissions.add(permName);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPermissions.addAll(widget.allPermissions.map((p) => p.permissionName));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedPermissions.clear();
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isSubmitting = true);
    final l10n = context.l10n;

    try {
      await widget.rbacService.updateRolePermissions(
        id: widget.role.id,
        permissions: _selectedPermissions.toList(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.notify(
          l10n.permissionsUpdatedSuccess(widget.role.roleName),
          isError: false,
        );
        widget.onPermissionsUpdated();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        widget.notify(
          e.toString().replaceFirst('ApiException: ', ''),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    final isSystemRole = widget.role.isSystemRole || widget.role.roleName == 'ROLE_NON_LOGIN';

    // Filter permissions by search query
    final filteredPerms = widget.allPermissions.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final nameMatch = p.permissionName.toLowerCase().contains(q);
      final descMatch = p.description?.toLowerCase().contains(q) ?? false;
      final groupMatch = RbacCategoryHelper.getCategoryTitle(
        RbacCategoryHelper.extractGroup(p.permissionName),
        isVi: isVi,
      ).toLowerCase().contains(q);
      return nameMatch || descMatch || groupMatch;
    }).toList();

    // Group filtered permissions by type
    final groupedMap = RbacCategoryHelper.groupPermissions(filteredPerms);

    final totalSelected = _selectedPermissions.length;
    final totalAvailable = widget.allPermissions.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(JoppeShapes.large)),
      elevation: 10,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.role.roleName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: JoppeSpacing.sm),
                            RoleTypeBadge(isSystemRole: isSystemRole),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.editPermissions,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.close,
                  ),
                ],
              ),
              const SizedBox(height: JoppeSpacing.md),

              // Search & Bulk Action Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.sm, vertical: JoppeSpacing.xs),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(60),
                  borderRadius: BorderRadius.circular(JoppeShapes.medium),
                  border: Border.all(color: cs.outlineVariant.withAlpha(70)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: l10n.searchPermissionsHint,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: JoppeSpacing.sm),
                    // Summary Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalSelected/$totalAvailable',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: JoppeSpacing.xs),
                    TextButton(
                      onPressed: _selectAll,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(l10n.selectAll, style: const TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: _deselectAll,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(l10n.deselectAll, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: JoppeSpacing.md),

              // Grouped Permissions List
              Expanded(
                child: groupedMap.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noPermissionsFound,
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
                            selectedPermissions: _selectedPermissions,
                            onTogglePermission: _togglePermission,
                            isEditable: true,
                          );
                        },
                      ),
              ),
              const SizedBox(height: JoppeSpacing.md),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: JoppeSpacing.sm),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _handleSave,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(l10n.savePermissions),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
