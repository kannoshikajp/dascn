import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

enum WarehouseStockFilter {
  all,
  inStock,
  lowStock,
  outOfStock;
}

/// Molecule: Filter bar for warehouse stock management with search query,
/// stock status pills (All, In Stock, Low Stock, Out of Stock),
/// filter visibility toggle, reset, and manual refresh.
class WarehouseFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final WarehouseStockFilter selectedFilter;
  final ValueChanged<WarehouseStockFilter> onSelectFilter;
  final VoidCallback onSearchChanged;
  final VoidCallback onReset;
  final VoidCallback onRefresh;
  final int totalCount;
  final int inStockCount;
  final int lowStockCount;
  final int outOfStockCount;
  final bool initialShowOptions;

  const WarehouseFilterBar({
    super.key,
    required this.searchController,
    required this.selectedFilter,
    required this.onSelectFilter,
    required this.onSearchChanged,
    required this.onReset,
    required this.onRefresh,
    this.totalCount = 0,
    this.inStockCount = 0,
    this.lowStockCount = 0,
    this.outOfStockCount = 0,
    this.initialShowOptions = true,
  });

  @override
  State<WarehouseFilterBar> createState() => _WarehouseFilterBarState();
}

class _WarehouseFilterBarState extends State<WarehouseFilterBar> {
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

    final isFiltered = widget.selectedFilter != WarehouseStockFilter.all;

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
                      hintText: l10n.searchWarehouseHint,
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
                    // Toggle show filter options button
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
                          if (isFiltered) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '1',
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
                      tooltip: l10n.refreshStockTooltip,
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

              // Status filter pills
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
                    isSelected: widget.selectedFilter == WarehouseStockFilter.all,
                    color: cs.primary,
                    label: l10n.allStock,
                    count: widget.totalCount,
                    onToggle: () => widget.onSelectFilter(WarehouseStockFilter.all),
                  ),
                  _buildPill(
                    context: context,
                    isSelected: widget.selectedFilter == WarehouseStockFilter.inStock,
                    color: Colors.green.shade700,
                    label: l10n.inStockOnly,
                    count: widget.inStockCount,
                    icon: Icons.check_circle_outline,
                    onToggle: () => widget.onSelectFilter(WarehouseStockFilter.inStock),
                  ),
                  _buildPill(
                    context: context,
                    isSelected: widget.selectedFilter == WarehouseStockFilter.lowStock,
                    color: Colors.orange.shade800,
                    label: l10n.lowStockOnly,
                    count: widget.lowStockCount,
                    icon: Icons.warning_amber_rounded,
                    onToggle: () => widget.onSelectFilter(WarehouseStockFilter.lowStock),
                  ),
                  _buildPill(
                    context: context,
                    isSelected: widget.selectedFilter == WarehouseStockFilter.outOfStock,
                    color: cs.error,
                    label: l10n.outOfStockOnly,
                    count: widget.outOfStockCount,
                    icon: Icons.error_outline,
                    onToggle: () => widget.onSelectFilter(WarehouseStockFilter.outOfStock),
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
