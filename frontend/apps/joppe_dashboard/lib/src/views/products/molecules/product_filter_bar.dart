import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

enum PriceRangePreset {
  under5m,
  from5mTo15m,
  from15mTo30m,
  over30m;

  bool matches(double price) {
    switch (this) {
      case PriceRangePreset.under5m:
        return price < 5000000;
      case PriceRangePreset.from5mTo15m:
        return price >= 5000000 && price <= 15000000;
      case PriceRangePreset.from15mTo30m:
        return price > 15000000 && price <= 30000000;
      case PriceRangePreset.over30m:
        return price > 30000000;
    }
  }
}

/// Molecule: Filter bar for products catalog with search query,
/// price range preset pills, category pills, and status toggle.
class ProductFilterBar extends StatefulWidget {
  final TextEditingController searchController;
  final List<CategoryItem> categories;
  final Set<int> includedCategoryIds;
  final Set<int> excludedCategoryIds;
  final Set<PriceRangePreset> includedPricePresets;
  final Set<PriceRangePreset> excludedPricePresets;
  final bool? selectedActiveFilter;
  final ValueChanged<int> onToggleCategory;
  final ValueChanged<PriceRangePreset> onTogglePricePreset;
  final ValueChanged<bool?> onSelectStatus;
  final VoidCallback onClearAllCategories;
  final VoidCallback onClearAllPrices;
  final VoidCallback onSearchChanged;
  final VoidCallback onReset;
  final VoidCallback onAddNewProduct;
  final VoidCallback? onExportCsv;
  final bool initialShowOptions;

  const ProductFilterBar({
    super.key,
    required this.searchController,
    required this.categories,
    required this.includedCategoryIds,
    required this.excludedCategoryIds,
    required this.includedPricePresets,
    required this.excludedPricePresets,
    required this.selectedActiveFilter,
    required this.onToggleCategory,
    required this.onTogglePricePreset,
    required this.onSelectStatus,
    required this.onClearAllCategories,
    required this.onClearAllPrices,
    required this.onSearchChanged,
    required this.onReset,
    required this.onAddNewProduct,
    this.onExportCsv,
    this.initialShowOptions = true,
  });

  @override
  State<ProductFilterBar> createState() => _ProductFilterBarState();
}

class _ProductFilterBarState extends State<ProductFilterBar> {
  late bool _showOptions;

  @override
  void initState() {
    super.initState();
    _showOptions = widget.initialShowOptions;
  }

  Widget _buildPill({
    required BuildContext context,
    required bool isIncluded,
    bool isExcluded = false,
    required Color color,
    required String label,
    required VoidCallback onToggle,
    bool showDot = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = isIncluded || isExcluded;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExcluded) ...[
            Icon(Icons.remove_circle_outline_rounded, size: 13, color: Colors.red.shade700),
            const SizedBox(width: 5),
          ] else if (isIncluded) ...[
            Icon(Icons.check_rounded, size: 13, color: color),
            const SizedBox(width: 5),
          ] else if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isExcluded
                  ? Colors.red.shade700
                  : isIncluded
                      ? color
                      : cs.onSurfaceVariant,
              decoration: isExcluded ? TextDecoration.lineThrough : null,
              decorationColor: Colors.red.shade700,
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
          color: isExcluded
              ? Colors.red.shade400
              : isIncluded
                  ? color
                  : cs.outlineVariant.withAlpha(80),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      backgroundColor: cs.surfaceContainerLow,
      selectedColor: isExcluded ? Colors.red.withAlpha(30) : color.withAlpha(35),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final activeFilterCount = widget.includedCategoryIds.length +
        widget.excludedCategoryIds.length +
        widget.includedPricePresets.length +
        widget.excludedPricePresets.length +
        (widget.selectedActiveFilter != null ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary search & actions row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  hintText: l10n.searchProductHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: widget.searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            widget.searchController.clear();
                            widget.onSearchChanged();
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                ),
                onChanged: (_) => widget.onSearchChanged(),
              ),
            ),
            const SizedBox(width: JoppeSpacing.sm),
            // Show/Hide filter toggle button
            FilledButton.tonalIcon(
              onPressed: () => setState(() => _showOptions = !_showOptions),
              icon: Icon(
                _showOptions ? Icons.filter_list_off : Icons.filter_list,
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
              style: _showOptions
                  ? FilledButton.styleFrom(
                      backgroundColor: cs.secondaryContainer,
                      foregroundColor: cs.onSecondaryContainer,
                    )
                  : null,
            ),
            const SizedBox(width: JoppeSpacing.sm),
            // Reset filters button
            IconButton.filledTonal(
              onPressed: widget.onReset,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.resetFiltersTooltip,
            ),
            if (widget.onExportCsv != null) ...[
              const SizedBox(width: JoppeSpacing.sm),
              OutlinedButton.icon(
                onPressed: widget.onExportCsv,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l10n.exportCsv),
              ),
            ],
            const SizedBox(width: JoppeSpacing.sm),
            // Add Product action
            FilledButton.icon(
              onPressed: widget.onAddNewProduct,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addProduct),
            ),
          ],
        ),

        // Collapsible Filter Pill Rows
        if (_showOptions) ...[
          const SizedBox(height: JoppeSpacing.sm),

          // 1. Category Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.categoryFilterLabel,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              _buildPill(
                context: context,
                isIncluded: widget.includedCategoryIds.isEmpty && widget.excludedCategoryIds.isEmpty,
                color: cs.primary,
                label: l10n.allCategoriesOption,
                onToggle: widget.onClearAllCategories,
                showDot: false,
              ),
              for (final cat in widget.categories)
                _buildPill(
                  context: context,
                  isIncluded: widget.includedCategoryIds.contains(cat.id),
                  isExcluded: widget.excludedCategoryIds.contains(cat.id),
                  color: Colors.blueAccent,
                  label: cat.categoryName,
                  onToggle: () => widget.onToggleCategory(cat.id),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Price Range Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.priceRangeFilterLabel,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              _buildPill(
                context: context,
                isIncluded: widget.includedPricePresets.isEmpty && widget.excludedPricePresets.isEmpty,
                color: cs.primary,
                label: l10n.allPricesOption,
                onToggle: widget.onClearAllPrices,
                showDot: false,
              ),
              _buildPill(
                context: context,
                isIncluded: widget.includedPricePresets.contains(PriceRangePreset.under5m),
                isExcluded: widget.excludedPricePresets.contains(PriceRangePreset.under5m),
                color: Colors.teal,
                label: l10n.under5mOption,
                onToggle: () => widget.onTogglePricePreset(PriceRangePreset.under5m),
              ),
              _buildPill(
                context: context,
                isIncluded: widget.includedPricePresets.contains(PriceRangePreset.from5mTo15m),
                isExcluded: widget.excludedPricePresets.contains(PriceRangePreset.from5mTo15m),
                color: Colors.indigo,
                label: l10n.from5mTo15mOption,
                onToggle: () => widget.onTogglePricePreset(PriceRangePreset.from5mTo15m),
              ),
              _buildPill(
                context: context,
                isIncluded: widget.includedPricePresets.contains(PriceRangePreset.from15mTo30m),
                isExcluded: widget.excludedPricePresets.contains(PriceRangePreset.from15mTo30m),
                color: Colors.purple,
                label: l10n.from15mTo30mOption,
                onToggle: () => widget.onTogglePricePreset(PriceRangePreset.from15mTo30m),
              ),
              _buildPill(
                context: context,
                isIncluded: widget.includedPricePresets.contains(PriceRangePreset.over30m),
                isExcluded: widget.excludedPricePresets.contains(PriceRangePreset.over30m),
                color: Colors.deepOrange,
                label: l10n.over30mOption,
                onToggle: () => widget.onTogglePricePreset(PriceRangePreset.over30m),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3. Status Pills
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.statusFilterLabel,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              _buildPill(
                context: context,
                isIncluded: widget.selectedActiveFilter == null,
                color: cs.primary,
                label: l10n.allStatusOption,
                onToggle: () => widget.onSelectStatus(null),
                showDot: false,
              ),
              _buildPill(
                context: context,
                isIncluded: widget.selectedActiveFilter == true,
                color: Colors.green,
                label: l10n.activeOnlyOption,
                onToggle: () => widget.onSelectStatus(true),
              ),
              _buildPill(
                context: context,
                isIncluded: widget.selectedActiveFilter == false,
                color: cs.error,
                label: l10n.inactiveOnlyOption,
                onToggle: () => widget.onSelectStatus(false),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
