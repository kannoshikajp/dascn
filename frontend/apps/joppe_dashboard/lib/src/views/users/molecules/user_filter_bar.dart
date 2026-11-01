import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Molecule: Search & filter bar for user accounts with role & status pills,
/// options toggling, filter resetting, and Add User action.
class UserFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final List<RoleItem> roles;
  final int? selectedRoleId;
  final bool? selectedActiveFilter;
  final ValueChanged<int?> onSelectRole;
  final ValueChanged<bool?> onSelectStatus;
  final VoidCallback onSearchChanged;
  final VoidCallback onReset;
  final VoidCallback onRefresh;
  final VoidCallback onAddUser;
  final int totalCount;
  final int activeCount;
  final int suspendedCount;
  final Map<int, int> roleCounts;
  final bool initialShowOptions;

  const UserFilterBar({
    super.key,
    required this.searchController,
    required this.roles,
    required this.selectedRoleId,
    required this.selectedActiveFilter,
    required this.onSelectRole,
    required this.onSelectStatus,
    required this.onSearchChanged,
    required this.onReset,
    required this.onRefresh,
    required this.onAddUser,
    this.totalCount = 0,
    this.activeCount = 0,
    this.suspendedCount = 0,
    this.roleCounts = const {},
    this.initialShowOptions = true,
  });

  @override
  State<UserFilterBar> createState() => _UserFilterBarState();
}

class _UserFilterBarState extends State<UserFilterBar> {
  late bool _showFilterOptions;

  @override
  void initState() {
    super.initState();
    _showFilterOptions = widget.initialShowOptions;
  }

  Widget _buildPill({
    required BuildContext context,
    required bool isSelected,
    required Color color,
    required String label,
    required int count,
    required VoidCallback onToggle,
    IconData? icon,
  }) {
    final cs = Theme.of(context).colorScheme;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: isSelected ? color : cs.onSurfaceVariant),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(40) : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onToggle(),
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : cs.outlineVariant.withAlpha(80),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      backgroundColor: cs.surfaceContainerLow,
      selectedColor: color.withAlpha(35),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final hasActiveFilter = widget.selectedRoleId != null || widget.selectedActiveFilter != null;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top action bar
            LayoutBuilder(
              builder: (context, constraints) {
                final searchWidth = constraints.maxWidth < 380 ? constraints.maxWidth : 320.0;

                final searchField = SizedBox(
                  width: searchWidth,
                  child: TextField(
                    controller: widget.searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchUsersHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: widget.searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                widget.searchController.clear();
                                widget.onSearchChanged();
                              },
                            )
                          : null,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(JoppeShapes.small),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (_) => widget.onSearchChanged(),
                    onSubmitted: (_) => widget.onSearchChanged(),
                  ),
                );

                final actionButtons = Wrap(
                  spacing: JoppeSpacing.sm,
                  runSpacing: JoppeSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Toggle filters options
                    FilledButton.tonalIcon(
                      onPressed: () => setState(() => _showFilterOptions = !_showFilterOptions),
                      icon: Icon(
                        _showFilterOptions ? Icons.filter_list_off : Icons.filter_list,
                        size: 18,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.filterButton),
                          if (hasActiveFilter) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${(widget.selectedRoleId != null ? 1 : 0) + (widget.selectedActiveFilter != null ? 1 : 0)}',
                                style: TextStyle(
                                  color: cs.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      style: _showFilterOptions
                          ? FilledButton.styleFrom(
                              backgroundColor: cs.secondaryContainer,
                              foregroundColor: cs.onSecondaryContainer,
                            )
                          : null,
                    ),

                    // Reset filters button
                    IconButton.filledTonal(
                      onPressed: widget.onReset,
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: l10n.resetFiltersTooltip,
                    ),

                    // Manual refresh button
                    IconButton.filledTonal(
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.sync, size: 18),
                      tooltip: l10n.refreshUsersTooltip,
                    ),

                    // Add User button
                    FilledButton.icon(
                      onPressed: widget.onAddUser,
                      icon: const Icon(Icons.person_add, size: 18),
                      label: Text(l10n.addUser),
                    ),
                  ],
                );

                return Wrap(
                  spacing: JoppeSpacing.md,
                  runSpacing: JoppeSpacing.sm,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    searchField,
                    actionButtons,
                  ],
                );
              },
            ),

            // Collapsible filter pills section
            if (_showFilterOptions) ...[
              const SizedBox(height: JoppeSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: JoppeSpacing.sm),

              // Role pills
              Wrap(
                spacing: JoppeSpacing.sm,
                runSpacing: JoppeSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n.roleFilterLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: JoppeSpacing.xs),
                  _buildPill(
                    context: context,
                    isSelected: widget.selectedRoleId == null,
                    color: cs.primary,
                    label: l10n.allRoles,
                    count: widget.totalCount,
                    onToggle: () => widget.onSelectRole(null),
                  ),
                  ...widget.roles
                      .where((r) => !r.roleName.toUpperCase().contains('NON_LOGIN'))
                      .map((r) {
                    final isSel = widget.selectedRoleId == r.id;
                    final count = widget.roleCounts[r.id] ?? 0;
                    return _buildPill(
                      context: context,
                      isSelected: isSel,
                      color: r.roleName.contains('ADMIN')
                          ? cs.primary
                          : (r.roleName.contains('STAFF') ? Colors.teal.shade700 : cs.secondary),
                      label: l10n.userRoleLabel(r.roleName),
                      count: count,
                      onToggle: () => widget.onSelectRole(isSel ? null : r.id),
                    );
                  }),
                ],
              ),
              const SizedBox(height: JoppeSpacing.sm),

              // Status pills
              Wrap(
                spacing: JoppeSpacing.sm,
                runSpacing: JoppeSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n.statusFilterLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: JoppeSpacing.xs),
                  _buildPill(
                    context: context,
                    isSelected: widget.selectedActiveFilter == null,
                    color: cs.primary,
                    label: l10n.allStatus,
                    count: widget.totalCount,
                    onToggle: () => widget.onSelectStatus(null),
                  ),
                  _buildPill(
                    context: context,
                    isSelected: widget.selectedActiveFilter == true,
                    color: Colors.green.shade700,
                    label: l10n.activeOnly,
                    count: widget.activeCount,
                    icon: Icons.check_circle_outline,
                    onToggle: () => widget.onSelectStatus(widget.selectedActiveFilter == true ? null : true),
                  ),
                  _buildPill(
                    context: context,
                    isSelected: widget.selectedActiveFilter == false,
                    color: cs.error,
                    label: l10n.suspendedOnly,
                    count: widget.suspendedCount,
                    icon: Icons.block_outlined,
                    onToggle: () => widget.onSelectStatus(widget.selectedActiveFilter == false ? null : false),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
