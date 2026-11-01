import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../utils/rbac_category_helper.dart';
import 'permission_group_card.dart';

/// Molecule: Modal dialog to create a new role, with initial permissions selected via grouped pills.
class CreateRoleDialog extends StatefulWidget {
  final List<PermissionItem> allPermissions;
  final RbacManagementService rbacService;
  final VoidCallback onRoleCreated;
  final void Function(String message, {bool isError}) notify;

  const CreateRoleDialog({
    super.key,
    required this.allPermissions,
    required this.rbacService,
    required this.onRoleCreated,
    required this.notify,
  });

  @override
  State<CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends State<CreateRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedPermissions = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final l10n = context.l10n;

    try {
      await widget.rbacService.createRole(
        roleName: _nameController.text.trim().toUpperCase(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        permissions: _selectedPermissions.toList(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.notify(l10n.roleCreatedSuccess, isError: false);
        widget.onRoleCreated();
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

    final groupedMap = RbacCategoryHelper.groupPermissions(widget.allPermissions);

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
                    child: Text(
                      l10n.createRoleTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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

              // Role Form fields
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.roleNameLabel,
                        hintText: 'ROLE_',
                        prefixIcon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return l10n.roleNameRequired;
                        }
                        if (!val.trim().toUpperCase().startsWith('ROLE_')) {
                          return l10n.roleNameMustStartWithRole;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        prefixIcon: const Icon(Icons.description_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: JoppeSpacing.md),

              // Permissions Header with Bulk Actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.assignPermissions,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: JoppeSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedPermissions.length}/${widget.allPermissions.length}',
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
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.selectAll, style: const TextStyle(fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: _deselectAll,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.deselectAll, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: JoppeSpacing.xs),

              // Grouped Permissions List
              Expanded(
                child: ListView.builder(
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
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add, size: 18),
                    label: Text(l10n.addRole),
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
