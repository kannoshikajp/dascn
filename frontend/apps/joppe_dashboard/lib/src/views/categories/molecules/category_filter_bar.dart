import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

enum CategoryHierarchyFilter {
  all,
  rootOnly,
  subOnly;
}

/// Molecule: Filter bar for category management with search query,
/// status toggle pills, hierarchy level pills, view mode switcher,
/// expand/collapse tree actions, and Add Category trigger.
class CategoryFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final bool? selectedActiveFilter;
  final CategoryHierarchyFilter selectedHierarchyFilter;
  final int selectedViewIndex; // 0 = Tree, 1 = List
  final ValueChanged<bool?> onSelectStatus;
  final ValueChanged<CategoryHierarchyFilter> onSelectHierarchy;
  final ValueChanged<int> onSelectViewMode;
  final VoidCallback onSearchChanged;
  final VoidCallback onReset;
  final VoidCallback onAddCategory;
  final VoidCallback? onExportCsv;
  final VoidCallback? onExpandAll;
  final VoidCallback? onCollapseAll;
  final bool initialShowOptions;

  const CategoryFilterBar({
    super.key,
    required this.searchController,
    required this.selectedActiveFilter,
    required this.selectedHierarchyFilter,
    required this.selectedViewIndex,
    required this.onSelectStatus,
    required this.onSelectHierarchy,
    required this.onSelectViewMode,
    required this.onSearchChanged,
    required this.onReset,
    required this.onAddCategory,
    this.onExportCsv,
    this.onExpandAll,
    this.onCollapseAll,
    this.initialShowOptions = true,
  });

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
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

    final activeFilterCount = (widget.selectedActiveFilter != null ? 1 : 0) +
        (widget.selectedViewIndex == 1 && widget.selectedHierarchyFilter != CategoryHierarchyFilter.all ? 1 : 0);

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
                final searchWidth = constraints.maxWidth < 360 ? constraints.maxWidth : 280.0;

                final searchField = SizedBox(
                  width: searchWidth,
                  child: TextField(
                    controller: widget.searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchCategoriesHint,
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
                  ),
                );

                final actionButtons = Wrap(
                  spacing: JoppeSpacing.sm,
                  runSpacing: JoppeSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Toggle show filter options button (before reset button)
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
                          if (activeFilterCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$activeFilterCount',
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

                    // View mode switcher: Tree vs List
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                          value: 0,
                          icon: const Icon(Icons.account_tree_outlined, size: 16),
                          label: Text(l10n.treeView),
                        ),
                        ButtonSegment(
                          value: 1,
                          icon: const Icon(Icons.table_rows_outlined, size: 16),
                          label: Text(l10n.flatView),
                        ),
                      ],
                      selected: {widget.selectedViewIndex},
                      onSelectionChanged: (val) => widget.onSelectViewMode(val.first),
                    ),

                    // Export CSV button
                    if (widget.onExportCsv != null)
                      OutlinedButton.icon(
                        onPressed: widget.onExportCsv,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(l10n.exportCsv),
                      ),

                    // Add Category CTA button
                    FilledButton.icon(
                      onPressed: widget.onAddCategory,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addCategory),
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

            // Collapsible filter options section
            if (_showFilterOptions) ...[
              const SizedBox(height: JoppeSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: JoppeSpacing.sm),

              // Filter pills row (wrap to new line cleanly)
              Wrap(
                spacing: JoppeSpacing.md,
                runSpacing: JoppeSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Status filter pills
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildPill(
                            context: context,
                            isSelected: widget.selectedActiveFilter == null,
                            color: cs.primary,
                            label: l10n.allStatusOption,
                            onToggle: () => widget.onSelectStatus(null),
                          ),
                          _buildPill(
                            context: context,
                            isSelected: widget.selectedActiveFilter == true,
                            color: Colors.green.shade700,
                            label: l10n.activeOnlyOption,
                            onToggle: () => widget.onSelectStatus(true),
                          ),
                          _buildPill(
                            context: context,
                            isSelected: widget.selectedActiveFilter == false,
                            color: Colors.grey.shade700,
                            label: l10n.inactiveOnlyOption,
                            onToggle: () => widget.onSelectStatus(false),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Hierarchy Level filter pills (only applies to Table / List mode)
                  if (widget.selectedViewIndex == 1) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.levelFilterLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: JoppeSpacing.xs),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildPill(
                              context: context,
                              isSelected: widget.selectedHierarchyFilter == CategoryHierarchyFilter.all,
                              color: cs.primary,
                              label: l10n.allHierarchyOption,
                              onToggle: () => widget.onSelectHierarchy(CategoryHierarchyFilter.all),
                            ),
                            _buildPill(
                              context: context,
                              isSelected: widget.selectedHierarchyFilter == CategoryHierarchyFilter.rootOnly,
                              color: Colors.blue.shade700,
                              label: l10n.rootHierarchyOption,
                              onToggle: () => widget.onSelectHierarchy(CategoryHierarchyFilter.rootOnly),
                            ),
                            _buildPill(
                              context: context,
                              isSelected: widget.selectedHierarchyFilter == CategoryHierarchyFilter.subOnly,
                              color: Colors.purple.shade700,
                              label: l10n.subHierarchyOption,
                              onToggle: () => widget.onSelectHierarchy(CategoryHierarchyFilter.subOnly),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  // Tree actions (Expand all / Collapse all) if tree view is selected
                  if (widget.selectedViewIndex == 0 &&
                      widget.onExpandAll != null &&
                      widget.onCollapseAll != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: widget.onExpandAll,
                          icon: const Icon(Icons.unfold_more, size: 14),
                          label: Text(l10n.expandAll, style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                        const SizedBox(width: 6),
                        OutlinedButton.icon(
                          onPressed: widget.onCollapseAll,
                          icon: const Icon(Icons.unfold_less, size: 14),
                          label: Text(l10n.collapseAll, style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
