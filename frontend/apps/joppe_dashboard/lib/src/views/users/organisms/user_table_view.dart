import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/user_action_menu.dart';
import '../atoms/user_avatar.dart';
import '../atoms/user_role_badge.dart';
import '../atoms/user_status_badge.dart';

/// Organism: Responsive tabular view displaying user accounts with dual-axis scrolling,
/// overflow truncation protection, and row actions.
class UserTableView extends StatefulWidget {
  final List<UserSummary> users;
  final ValueChanged<UserSummary> onEditUser;
  final ValueChanged<UserSummary> onToggleStatus;
  final ValueChanged<UserSummary> onDeleteUser;
  final String Function(DateTime?) formatDate;

  const UserTableView({
    super.key,
    required this.users,
    required this.onEditUser,
    required this.onToggleStatus,
    required this.onDeleteUser,
    required this.formatDate,
  });

  @override
  State<UserTableView> createState() => _UserTableViewState();
}

class _UserTableViewState extends State<UserTableView> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (widget.users.isEmpty) {
      return Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(JoppeShapes.medium),
          side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(JoppeSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_search_outlined, size: 54, color: cs.onSurfaceVariant.withAlpha(120)),
                const SizedBox(height: JoppeSpacing.sm),
                Text(
                  l10n.noUsersFound,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(JoppeShapes.medium),
        side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
                      horizontalMargin: 12,
                      columnSpacing: 16,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 64,
                      columns: [
                        DataColumn(
                          label: Text(l10n.userCol, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.roleCol, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.phoneCol, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.statusCol, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.joinedAtCol, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.actionCol, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                      rows: widget.users.map((u) {
                        return DataRow(
                          cells: [
                            // User Column: Avatar + Name + Email
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 260),
                                child: Row(
                                  children: [
                                    UserAvatar(user: u, radius: 18),
                                    const SizedBox(width: JoppeSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Tooltip(
                                            message: u.fullName,
                                            child: Text(
                                              u.fullName.isNotEmpty ? u.fullName : u.email,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          Tooltip(
                                            message: u.email,
                                            child: Text(
                                              u.email,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Role
                            DataCell(
                              UserRoleBadge(roleName: u.roleName),
                            ),

                            // Phone
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 140),
                                child: Text(
                                  u.phoneNumber?.isNotEmpty == true ? u.phoneNumber! : '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: u.phoneNumber?.isNotEmpty == true ? cs.onSurface : cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),

                            // Status
                            DataCell(
                              UserStatusBadge(isActive: u.isActive),
                            ),

                            // Joined Date
                            DataCell(
                              Text(
                                widget.formatDate(u.createdAt),
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                              ),
                            ),

                            // Actions
                            DataCell(
                              UserActionMenu(
                                user: u,
                                onEdit: () => widget.onEditUser(u),
                                onToggleStatus: () => widget.onToggleStatus(u),
                                onDelete: () => widget.onDeleteUser(u),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
