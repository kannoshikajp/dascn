import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

class RbacView extends StatefulWidget {
  final RbacManagementService rbacService;

  const RbacView({
    super.key,
    required this.rbacService,
  });

  @override
  State<RbacView> createState() => _RbacViewState();
}

class _RbacViewState extends State<RbacView> {
  List<RoleItem> _roles = [];
  List<PermissionItem> _allPermissions = [];
  bool _isLoading = true;
  String? _error;
  RoleItem? _selectedRole;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final roles = await widget.rbacService.listRoles();
      final permissions = await widget.rbacService.listPermissions();
      if (mounted) {
        setState(() {
          _roles = roles;
          _allPermissions = permissions;
          if (_selectedRole != null) {
            _selectedRole = roles.firstWhere(
              (r) => r.id == _selectedRole!.id,
              orElse: () => roles.isNotEmpty ? roles.first : _selectedRole!,
            );
          } else if (roles.isNotEmpty) {
            _selectedRole = roles.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRole(RoleItem role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Role'),
        content: Text('Are you sure you want to delete role "${role.roleName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.rbacService.deleteRole(role.id);
        _showSnackbar('Role deleted');
        if (_selectedRole?.id == role.id) {
          _selectedRole = null;
        }
        _loadData();
      } catch (e) {
        _showSnackbar('Cannot delete role: $e');
      }
    }
  }

  void _showCreateRoleDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final selectedPerms = <String>{};
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create New Role'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Role Name (e.g. ROLE_MANAGER)',
                        hintText: 'ROLE_',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Role name is required';
                        if (!v.startsWith('ROLE_')) return 'Must start with ROLE_';
                        return null;
                      },
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: JoppeSpacing.md),
                    Text(
                      'Assign Initial Permissions:',
                      style: Theme.of(ctx).textTheme.labelLarge,
                    ),
                    const SizedBox(height: JoppeSpacing.xs),
                    ..._allPermissions.map((perm) {
                      final isChecked = selectedPerms.contains(perm.permissionName);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(perm.permissionName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(perm.description ?? ''),
                        value: isChecked,
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedPerms.add(perm.permissionName);
                            } else {
                              selectedPerms.remove(perm.permissionName);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await widget.rbacService.createRole(
                    roleName: nameCtrl.text.trim().toUpperCase(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    permissions: selectedPerms.toList(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnackbar('Role created successfully');
                  _loadData();
                } catch (e) {
                  _showSnackbar('Error creating role: $e');
                }
              },
              child: const Text('Create Role'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPermissionsDialog(RoleItem role) {
    final selectedPerms = Set<String>.from(role.permissions);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit Permissions for ${role.roleName}'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _allPermissions.map((perm) {
                  final isChecked = selectedPerms.contains(perm.permissionName);
                  return CheckboxListTile(
                    dense: true,
                    title: Text(perm.permissionName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(perm.description ?? ''),
                    value: isChecked,
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) {
                          selectedPerms.add(perm.permissionName);
                        } else {
                          selectedPerms.remove(perm.permissionName);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await widget.rbacService.updateRolePermissions(
                    id: role.id,
                    permissions: selectedPerms.toList(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnackbar('Permissions updated for ${role.roleName}');
                  _loadData();
                } catch (e) {
                  _showSnackbar('Error updating permissions: $e');
                }
              },
              child: const Text('Save Permissions'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: JoppeSpacing.md),
            FilledButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(JoppeSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Roles & Permissions Matrix', style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          'Manage system roles, granular API permissions, and access controls',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: JoppeSpacing.md),
                  FilledButton.icon(
                    onPressed: _showCreateRoleDialog,
                    icon: const Icon(Icons.add_moderator),
                    label: const Text('Add Role'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: JoppeSpacing.md),

          // Master-Detail Layout
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Roles List (Left Panel)
                SizedBox(
                  width: 320,
                  child: Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(JoppeSpacing.sm),
                      itemCount: _roles.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final r = _roles[idx];
                        final isSelected = _selectedRole?.id == r.id;
                        final isSystem = r.roleName == 'ROLE_ADMIN' ||
                            r.roleName == 'ROLE_CUSTOMER' ||
                            r.roleName == 'ROLE_STAFF' ||
                            r.roleName == 'ROLE_NON_LOGIN';

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: colorScheme.primaryContainer.withAlpha(80),
                          leading: Icon(
                            isSystem ? Icons.security : Icons.manage_accounts,
                            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                          title: Text(r.roleName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            r.description ?? (isSystem ? 'System built-in role' : 'Custom role'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Chip(
                            label: Text('${r.permissions.length} perms', style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          onTap: () => setState(() => _selectedRole = r),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: JoppeSpacing.md),

                // Role Detail / Permission Config (Right Panel)
                Expanded(
                  child: _selectedRole == null
                      ? const Card(
                          child: Center(child: Text('Select a role from the list to view permissions.')),
                        )
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(JoppeSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: JoppeSpacing.sm,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                _selectedRole!.roleName,
                                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                              if (_selectedRole!.roleName == 'ROLE_ADMIN' ||
                                                  _selectedRole!.roleName == 'ROLE_CUSTOMER' ||
                                                  _selectedRole!.roleName == 'ROLE_STAFF' ||
                                                  _selectedRole!.roleName == 'ROLE_NON_LOGIN')
                                                Chip(
                                                  label: const Text('System Protected', style: TextStyle(fontSize: 11)),
                                                  backgroundColor: colorScheme.secondaryContainer,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: JoppeSpacing.xs),
                                          Text(
                                            _selectedRole!.description ?? 'No description provided.',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: JoppeSpacing.sm),
                                    Row(
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _showEditPermissionsDialog(_selectedRole!),
                                          icon: const Icon(Icons.edit_note),
                                          label: const Text('Configure Permissions'),
                                        ),
                                        if (_selectedRole!.roleName != 'ROLE_ADMIN' &&
                                            _selectedRole!.roleName != 'ROLE_CUSTOMER' &&
                                            _selectedRole!.roleName != 'ROLE_STAFF' &&
                                            _selectedRole!.roleName != 'ROLE_NON_LOGIN') ...[
                                          const SizedBox(width: JoppeSpacing.xs),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            color: colorScheme.error,
                                            onPressed: () => _deleteRole(_selectedRole!),
                                            tooltip: 'Delete Custom Role',
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: JoppeSpacing.xl),
                                Text(
                                  'Granted Permissions (${_selectedRole!.permissions.length})',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: JoppeSpacing.sm),
                                Expanded(
                                  child: _selectedRole!.permissions.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No permissions assigned to this role.',
                                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                                          ),
                                        )
                                      : GridView.builder(
                                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 320,
                                            mainAxisExtent: 72,
                                            crossAxisSpacing: JoppeSpacing.sm,
                                            mainAxisSpacing: JoppeSpacing.sm,
                                          ),
                                          itemCount: _selectedRole!.permissions.length,
                                          itemBuilder: (context, idx) {
                                            final permName = _selectedRole!.permissions[idx];
                                            final permInfo = _allPermissions.firstWhere(
                                              (p) => p.permissionName == permName,
                                              orElse: () => PermissionItem(id: 0, permissionName: permName),
                                            );

                                            return Container(
                                              padding: const EdgeInsets.all(JoppeSpacing.sm),
                                              decoration: BoxDecoration(
                                                color: colorScheme.surfaceContainerHighest.withAlpha(120),
                                                borderRadius: BorderRadius.circular(JoppeShapes.small),
                                                border: Border.all(color: colorScheme.outlineVariant),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                                                      const SizedBox(width: JoppeSpacing.xs),
                                                      Expanded(
                                                        child: Text(
                                                          permName,
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (permInfo.description != null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      permInfo.description!,
                                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
