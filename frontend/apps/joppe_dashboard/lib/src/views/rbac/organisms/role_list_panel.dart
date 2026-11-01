import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Organism: Master panel listing system and custom roles with search and selection.
class RoleListPanel extends StatefulWidget {
  final List<RoleItem> roles;
  final RoleItem? selectedRole;
  final ValueChanged<RoleItem> onSelectRole;
  final VoidCallback onAddRole;

  const RoleListPanel({
    super.key,
    required this.roles,
    required this.selectedRole,
    required this.onSelectRole,
    required this.onAddRole,
  });

  @override
  State<RoleListPanel> createState() => _RoleListPanelState();
}

class _RoleListPanelState extends State<RoleListPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final filteredRoles = widget.roles.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final nameMatch = r.roleName.toLowerCase().contains(q);
      final descMatch = r.description?.toLowerCase().contains(q) ?? false;
      return nameMatch || descMatch;
    }).toList();

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(JoppeShapes.medium),
        side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar header
          Padding(
            padding: const EdgeInsets.all(JoppeSpacing.sm + 2),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: l10n.searchRolesHint,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(JoppeShapes.small),
                        borderSide: BorderSide(color: cs.outlineVariant.withAlpha(80)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: JoppeSpacing.xs),
                IconButton.filledTonal(
                  onPressed: widget.onAddRole,
                  icon: const Icon(Icons.add_moderator, size: 20),
                  tooltip: l10n.addRole,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Role list
          Expanded(
            child: filteredRoles.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(JoppeSpacing.md),
                      child: Text(
                        l10n.noRolesFound,
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(JoppeSpacing.xs),
                    itemCount: filteredRoles.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 4),
                    itemBuilder: (context, idx) {
                      final r = filteredRoles[idx];
                      final isSelected = widget.selectedRole?.id == r.id;
                      final isSystem = r.isSystemRole || r.roleName == 'ROLE_NON_LOGIN';

                      return InkWell(
                        onTap: () => widget.onSelectRole(r),
                        borderRadius: BorderRadius.circular(JoppeShapes.small),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? cs.primaryContainer.withAlpha(90) : Colors.transparent,
                            borderRadius: BorderRadius.circular(JoppeShapes.small),
                            border: isSelected ? Border.all(color: cs.primary.withAlpha(120)) : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cs.primary.withAlpha(30)
                                      : cs.surfaceContainerHighest.withAlpha(100),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSystem ? Icons.shield_outlined : Icons.tune_rounded,
                                  size: 16,
                                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: JoppeSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      r.roleName,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 13,
                                        color: isSelected ? cs.primary : cs.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      r.description ?? (isSystem ? l10n.systemBuiltinRole : l10n.customRole),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: cs.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSelected ? cs.primary.withAlpha(30) : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${r.permissions.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                                  ),
                                ),
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
