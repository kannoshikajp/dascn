import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

class UsersView extends StatefulWidget {
  final UserManagementService userService;
  final RbacManagementService rbacService;

  const UsersView({
    super.key,
    required this.userService,
    required this.rbacService,
  });

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  List<UserSummary> _users = [];
  List<RoleItem> _roles = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int? _selectedRoleId;
  bool? _selectedActiveFilter;

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
      final users = await widget.userService.listUsers(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        roleId: _selectedRoleId,
        isActive: _selectedActiveFilter,
      );
      if (mounted) {
        setState(() {
          _roles = roles;
          _users = users;
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

  Future<void> _toggleStatus(UserSummary user) async {
    try {
      await widget.userService.updateStatus(user.id, !user.isActive);
      _loadData();
    } catch (e) {
      _showSnackbar('Failed to update status: $e');
    }
  }

  Future<void> _deleteUser(UserSummary user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to permanently delete "${user.fullName}" (${user.email})?'),
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
        await widget.userService.deleteUser(user.id);
        _showSnackbar('User deleted');
        _loadData();
      } catch (e) {
        _showSnackbar('Failed to delete user: $e');
      }
    }
  }

  void _showCreateDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    int selectedRole = _roles.isNotEmpty ? _roles.first.id : 1;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Address'),
                    validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: JoppeSpacing.sm),
                  TextFormField(
                    controller: passCtrl,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: JoppeSpacing.sm),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Full name required' : null,
                  ),
                  const SizedBox(height: JoppeSpacing.sm),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone Number (optional)'),
                  ),
                  const SizedBox(height: JoppeSpacing.sm),
                  DropdownButtonFormField<int>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: _roles
                        .map((r) => DropdownMenuItem(value: r.id, child: Text(r.roleName)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await widget.userService.createUser(
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text,
                    fullName: nameCtrl.text.trim(),
                    phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    roleId: selectedRole,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnackbar('User created successfully');
                  _loadData();
                } catch (e) {
                  _showSnackbar('Error creating user: $e');
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(UserSummary user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phoneNumber ?? '');
    int selectedRole = user.roleId;
    bool isActive = user.isActive;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${user.email}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: JoppeSpacing.sm),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone Number'),
                  ),
                  const SizedBox(height: JoppeSpacing.sm),
                  DropdownButtonFormField<int>(
                    initialValue: _roles.any((r) => r.id == selectedRole)
                        ? selectedRole
                        : (_roles.isNotEmpty ? _roles.first.id : 1),
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: _roles
                        .map((r) => DropdownMenuItem(value: r.id, child: Text(r.roleName)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: JoppeSpacing.sm),
                  SwitchListTile(
                    title: const Text('Account Active'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await widget.userService.updateUser(
                    id: user.id,
                    fullName: nameCtrl.text.trim(),
                    phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    roleId: selectedRole,
                    isActive: isActive,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnackbar('User updated successfully');
                  _loadData();
                } catch (e) {
                  _showSnackbar('Error updating user: $e');
                }
              },
              child: const Text('Save Changes'),
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

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Toolbar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(JoppeSpacing.md),
              child: Wrap(
                spacing: JoppeSpacing.md,
                runSpacing: JoppeSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by name or email...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        _searchQuery = val;
                        _loadData();
                      },
                    ),
                  ),
                  DropdownButton<int?>(
                    value: _selectedRoleId,
                    hint: const Text('All Roles'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Roles')),
                      ..._roles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.roleName))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedRoleId = val);
                      _loadData();
                    },
                  ),
                  DropdownButton<bool?>(
                    value: _selectedActiveFilter,
                    hint: const Text('All Status'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Status')),
                      DropdownMenuItem(value: true, child: Text('Active Only')),
                      DropdownMenuItem(value: false, child: Text('Suspended Only')),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedActiveFilter = val);
                      _loadData();
                    },
                  ),
                  FilledButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add User'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: JoppeSpacing.md),

          // User List / Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _users.isEmpty
                        ? const Center(child: Text('No users found.'))
                        : ListView.separated(
                            itemCount: _users.length,
                            separatorBuilder: (context, index) => const SizedBox(height: JoppeSpacing.xs),
                            itemBuilder: (context, idx) {
                              final u = _users[idx];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: u.roleName.contains('ADMIN')
                                        ? colorScheme.primaryContainer
                                        : colorScheme.surfaceContainerHigh,
                                    child: Text(
                                      u.fullName.isNotEmpty
                                          ? u.fullName.substring(0, 1).toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: u.roleName.contains('ADMIN')
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(width: JoppeSpacing.xs),
                                      Chip(
                                        label: Text(
                                          u.roleName,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  subtitle: Text('${u.email}${u.phoneNumber != null ? " • ${u.phoneNumber}" : ""}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Tooltip(
                                        message: u.isActive ? 'Active (click to suspend)' : 'Suspended (click to activate)',
                                        child: Switch(
                                          value: u.isActive,
                                          onChanged: (_) => _toggleStatus(u),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _showEditDialog(u),
                                        tooltip: 'Edit User',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: colorScheme.error,
                                        onPressed: () => _deleteUser(u),
                                        tooltip: 'Delete User',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
