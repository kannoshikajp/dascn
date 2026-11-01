import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../localization/dashboard_localizations.dart';
import 'rbac/molecules/create_role_dialog.dart';
import 'rbac/molecules/delete_role_dialog.dart';
import 'rbac/molecules/edit_permissions_dialog.dart';
import 'rbac/organisms/rbac_kpi_row.dart';
import 'rbac/organisms/role_detail_panel.dart';
import 'rbac/organisms/role_list_panel.dart';
import 'users/molecules/user_notification_dialog.dart';

/// Screen: RBAC Management View following Atomic Design.
/// Displays roles and permissions matrix, KPI metric summaries, master-detail role explorer,
/// and interactive pill-based permission editors with centered notification modals.
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
      final results = await Future.wait([
        widget.rbacService.listRoles(),
        widget.rbacService.listPermissions(),
      ]);

      if (mounted) {
        final roles = results[0] as List<RoleItem>;
        final permissions = results[1] as List<PermissionItem>;

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

  void _showNotification(String msg, {bool isError = false}) {
    if (!mounted) return;
    UserNotificationDialog.show(
      context: context,
      message: msg,
      type: isError ? NotificationType.error : NotificationType.success,
    );
  }

  void _showCreateRoleDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateRoleDialog(
        allPermissions: _allPermissions,
        rbacService: widget.rbacService,
        notify: (msg, {isError = false}) => _showNotification(msg, isError: isError),
        onRoleCreated: () {
          _loadData();
        },
      ),
    );
  }

  void _showEditPermissionsDialog(RoleItem role) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditPermissionsDialog(
        role: role,
        allPermissions: _allPermissions,
        rbacService: widget.rbacService,
        notify: (msg, {isError = false}) => _showNotification(msg, isError: isError),
        onPermissionsUpdated: () {
          _loadData();
        },
      ),
    );
  }

  void _showDeleteRoleDialog(RoleItem role) {
    showDialog<void>(
      context: context,
      builder: (_) => DeleteRoleDialog(
        role: role,
        rbacService: widget.rbacService,
        notify: (msg, {isError = false}) => _showNotification(msg, isError: isError),
        onRoleDeleted: () {
          if (_selectedRole?.id == role.id) {
            _selectedRole = null;
          }
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: JoppeSpacing.sm),
            Text(
              _error!,
              style: TextStyle(color: cs.error, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: JoppeSpacing.md),
            FilledButton.tonalIcon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.refreshUsersTooltip),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Toolbar
          Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(JoppeShapes.medium),
              side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.md, vertical: JoppeSpacing.sm + 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withAlpha(90),
                      borderRadius: BorderRadius.circular(JoppeShapes.small),
                    ),
                    child: Icon(Icons.security, size: 22, color: cs.primary),
                  ),
                  const SizedBox(width: JoppeSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.rbacMatrixTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          l10n.rbacSubtitle,
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: JoppeSpacing.sm),
                  FilledButton.icon(
                    onPressed: _showCreateRoleDialog,
                    icon: const Icon(Icons.add_moderator, size: 18),
                    label: Text(l10n.addRole),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: JoppeSpacing.md),

          // KPI Metric Row
          RbacKpiRow(
            roles: _roles,
            allPermissions: _allPermissions,
          ),
          const SizedBox(height: JoppeSpacing.md),

          // Master-Detail Roles and Permissions View
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Roles Explorer
                SizedBox(
                  width: 290,
                  child: RoleListPanel(
                    roles: _roles,
                    selectedRole: _selectedRole,
                    onSelectRole: (role) => setState(() => _selectedRole = role),
                    onAddRole: _showCreateRoleDialog,
                  ),
                ),
                const SizedBox(width: JoppeSpacing.md),

                // Right Panel: Role Details & Grouped Permissions
                Expanded(
                  child: RoleDetailPanel(
                    role: _selectedRole,
                    allPermissions: _allPermissions,
                    onEditPermissions: () => _showEditPermissionsDialog(_selectedRole!),
                    onDeleteRole: () => _showDeleteRoleDialog(_selectedRole!),
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
