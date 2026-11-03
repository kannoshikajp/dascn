import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../localization/dashboard_localizations.dart';
import 'warehouse/atoms/warehouse_action_menu.dart';
import 'warehouse/atoms/warehouse_kpi_card.dart';
import 'warehouse/atoms/warehouse_stock_badge.dart';
import 'warehouse/molecules/warehouse_adjust_dialog.dart';
import 'warehouse/molecules/warehouse_filter_bar.dart';
import 'warehouse/organisms/warehouse_kpi_row.dart';
import 'warehouse/organisms/warehouse_table_view.dart';

export 'warehouse/atoms/warehouse_action_menu.dart';
export 'warehouse/atoms/warehouse_kpi_card.dart';
export 'warehouse/atoms/warehouse_stock_badge.dart';
export 'warehouse/molecules/warehouse_adjust_dialog.dart';
export 'warehouse/molecules/warehouse_filter_bar.dart';
export 'warehouse/organisms/warehouse_kpi_row.dart';
export 'warehouse/organisms/warehouse_table_view.dart';

/// Screen: Warehouse stock view following Atomic Design principles.
/// Composed of:
/// - Organisms: WarehouseKpiRow, WarehouseTableView
/// - Molecules: WarehouseFilterBar, WarehouseAdjustDialog
/// - Atoms: WarehouseKpiCard, WarehouseStockBadge, WarehouseActionMenu
class WarehouseView extends StatefulWidget {
  final InventoryService inventoryService;

  const WarehouseView({
    super.key,
    required this.inventoryService,
  });

  @override
  State<WarehouseView> createState() => _WarehouseViewState();
}

class _WarehouseViewState extends State<WarehouseView> {
  final TextEditingController _searchController = TextEditingController();
  List<InventoryStockItem> _allItems = [];
  bool _isLoading = true;
  String? _error;
  WarehouseStockFilter _selectedFilter = WarehouseStockFilter.all;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStock() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.inventoryService.listStock(
        lowStockOnly: _selectedFilter == WarehouseStockFilter.lowStock ? true : null,
      );

      if (mounted) {
        setState(() {
          _allItems = items;
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

  List<InventoryStockItem> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();

    return _allItems.where((item) {
      // Query filter
      if (query.isNotEmpty) {
        final matches = item.productName.toLowerCase().contains(query) ||
            item.variantName.toLowerCase().contains(query) ||
            item.sku.toLowerCase().contains(query);
        if (!matches) return false;
      }

      // Status pill filter
      switch (_selectedFilter) {
        case WarehouseStockFilter.all:
          return true;
        case WarehouseStockFilter.inStock:
          return !item.isLowStock && !item.isOutOfStock;
        case WarehouseStockFilter.lowStock:
          return item.isLowStock;
        case WarehouseStockFilter.outOfStock:
          return item.isOutOfStock;
      }
    }).toList();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedFilter = WarehouseStockFilter.all;
    });
    _loadStock();
  }

  String _formatCurrency(double amount) {
    final isNeg = amount < 0;
    final abs = amount.abs().toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = abs.replaceAllMapped(reg, (m) => '${m[1]},');
    return '${isNeg ? '-' : ''}$formatted ₫';
  }

  String _resolveImageUrl(String url) => ApiClient.resolveUrl(url);

  void _openAdjustDialog(InventoryStockItem item) {
    showDialog(
      context: context,
      builder: (ctx) => WarehouseAdjustDialog(
        item: item,
        inventoryService: widget.inventoryService,
        onSuccess: _loadStock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final inStockCount = _allItems.where((i) => !i.isLowStock && !i.isOutOfStock).length;
    final lowStockCount = _allItems.where((i) => i.isLowStock).length;
    final outOfStockCount = _allItems.where((i) => i.isOutOfStock).length;

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. KPI Overview Row
          WarehouseKpiRow(
            stockItems: _allItems,
            formatCurrency: _formatCurrency,
          ),
          const SizedBox(height: JoppeSpacing.md),

          // 2. Filter Bar Molecule
          WarehouseFilterBar(
            searchController: _searchController,
            selectedFilter: _selectedFilter,
            totalCount: _allItems.length,
            inStockCount: inStockCount,
            lowStockCount: lowStockCount,
            outOfStockCount: outOfStockCount,
            onSelectFilter: (filter) {
              setState(() => _selectedFilter = filter);
              // If backend filter needed for lowStockOnly
              if (filter == WarehouseStockFilter.lowStock) {
                _loadStock();
              }
            },
            onSearchChanged: () => setState(() {}),
            onReset: _resetFilters,
            onRefresh: _loadStock,
          ),
          const SizedBox(height: JoppeSpacing.md),

          // 3. Tabular Content Display
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
                            Text('${l10n.retry}: $_error', style: TextStyle(color: cs.error)),
                            const SizedBox(height: JoppeSpacing.md),
                            FilledButton.tonal(
                              onPressed: _loadStock,
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : WarehouseTableView(
                        items: _filteredItems,
                        onAdjustStock: _openAdjustDialog,
                        formatCurrency: _formatCurrency,
                        resolveImageUrl: _resolveImageUrl,
                      ),
          ),
        ],
      ),
    );
  }
}
