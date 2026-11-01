import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../localization/dashboard_localizations.dart';
import 'users/molecules/create_user_dialog.dart';
import 'users/molecules/delete_user_dialog.dart';
import 'users/molecules/edit_user_dialog.dart';
import 'users/molecules/user_filter_bar.dart';
import 'users/molecules/user_notification_dialog.dart';
import 'users/organisms/user_kpi_row.dart';
import 'users/organisms/user_table_view.dart';

/// Screen: User accounts management view following Atomic Design.
/// Displays KPI metrics, flexible role/status filters, responsive data table, and CRUD dialogs.
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
  final TextEditingController _searchController = TextEditingController();

  List<UserSummary> _allUsers = [];
  List<UserSummary> _filteredUsers = [];
  List<RoleItem> _roles = [];

  bool _isLoading = true;
  String? _error;

  int? _selectedRoleId;
  bool? _selectedActiveFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rolesFuture = widget.rbacService.listRoles();
      final usersFuture = widget.userService.listUsers();

      final results = await Future.wait([rolesFuture, usersFuture]);
      if (mounted) {
        final rawRoles = results[0] as List<RoleItem>;
        setState(() {
          _roles = rawRoles.where((r) => !r.roleName.toUpperCase().contains('NON_LOGIN')).toList();
          _allUsers = results[1] as List<UserSummary>;
          _applyFilters();
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

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    _filteredUsers = _allUsers.where((u) {
      // Role filter
      if (_selectedRoleId != null && u.roleId != _selectedRoleId) {
        return false;
      }

      // Status filter
      if (_selectedActiveFilter != null && u.isActive != _selectedActiveFilter) {
        return false;
      }

      // Query filter
      if (query.isNotEmpty) {
        final nameMatch = u.fullName.toLowerCase().contains(query);
        final emailMatch = u.email.toLowerCase().contains(query);
        final phoneMatch = u.phoneNumber?.toLowerCase().contains(query) ?? false;
        final roleMatch = u.roleName.toLowerCase().contains(query);
        return nameMatch || emailMatch || phoneMatch || roleMatch;
      }

      return true;
    }).toList();
  }

  void _onSearchChanged() {
    setState(() {
      _applyFilters();
    });
  }

  void _onSelectRole(int? roleId) {
    setState(() {
      _selectedRoleId = roleId;
      _applyFilters();
    });
  }

  void _onSelectStatus(bool? isActive) {
    setState(() {
      _selectedActiveFilter = isActive;
      _applyFilters();
    });
  }

  void _onResetFilters() {
    setState(() {
      _searchController.clear();
      _selectedRoleId = null;
      _selectedActiveFilter = null;
      _applyFilters();
    });
  }

  Future<void> _toggleStatus(UserSummary user) async {
    final newStatus = !user.isActive;
    try {
      await widget.userService.updateStatus(user.id, newStatus);
      _showNotification(context.l10n.statusUpdatedSuccess, type: NotificationType.success);
      _loadData();
    } catch (e) {
      _showNotification(
        e.toString().replaceFirst('ApiException: ', ''),
        type: NotificationType.error,
      );
    }
  }

  void _showCreateDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateUserDialog(
        userService: widget.userService,
        roles: _roles,
        onUserCreated: () {
          _showNotification(context.l10n.userCreatedSuccess, type: NotificationType.success);
          _loadData();
        },
      ),
    );
  }

  void _showEditDialog(UserSummary user) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditUserDialog(
        user: user,
        roles: _roles,
        userService: widget.userService,
        onUserUpdated: () {
          _showNotification(context.l10n.userUpdatedSuccess, type: NotificationType.success);
          _loadData();
        },
      ),
    );
  }

  void _showDeleteDialog(UserSummary user) {
    showDialog<bool>(
      context: context,
      builder: (_) => DeleteUserDialog(
        user: user,
        userService: widget.userService,
        onUserDeleted: () {
          _showNotification(context.l10n.userDeletedSuccess, type: NotificationType.success);
          _loadData();
        },
      ),
    );
  }

  void _showNotification(String msg, {NotificationType type = NotificationType.success}) {
    if (!mounted) return;
    UserNotificationDialog.show(
      context: context,
      message: msg,
      type: type,
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    // Calculate filter count metrics
    final totalCount = _allUsers.length;
    final activeCount = _allUsers.where((u) => u.isActive).length;
    final suspendedCount = _allUsers.where((u) => !u.isActive).length;
    final roleCounts = <int, int>{};
    for (final u in _allUsers) {
      roleCounts[u.roleId] = (roleCounts[u.roleId] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI summary row
          UserKpiRow(users: _allUsers),
          const SizedBox(height: JoppeSpacing.md),

          // Search and filter toolbar
          UserFilterBar(
            searchController: _searchController,
            roles: _roles,
            selectedRoleId: _selectedRoleId,
            selectedActiveFilter: _selectedActiveFilter,
            onSelectRole: _onSelectRole,
            onSelectStatus: _onSelectStatus,
            onSearchChanged: _onSearchChanged,
            onReset: _onResetFilters,
            onRefresh: _loadData,
            onAddUser: _showCreateDialog,
            totalCount: totalCount,
            activeCount: activeCount,
            suspendedCount: suspendedCount,
            roleCounts: roleCounts,
          ),
          const SizedBox(height: JoppeSpacing.md),

          // Main data view
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                      )
                    : UserTableView(
                        users: _filteredUsers,
                        onEditUser: _showEditDialog,
                        onToggleStatus: _toggleStatus,
                        onDeleteUser: _showDeleteDialog,
                        formatDate: _formatDate,
                      ),
          ),
        ],
      ),
    );
  }
}
