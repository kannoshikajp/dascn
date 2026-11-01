import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../localization/dashboard_localizations.dart';
import '../utils/file_download_helper.dart';
import 'products/atoms/product_variant_badge.dart';
import 'products/molecules/product_filter_bar.dart';
import 'products/molecules/product_form_dialog.dart';
import 'products/organisms/products_list_view.dart';

export 'products/atoms/product_variant_badge.dart';
export 'products/molecules/product_filter_bar.dart';
export 'products/molecules/product_form_dialog.dart';
export 'products/organisms/products_list_view.dart';

/// Screen: Product catalog management screen built following Atomic Design principles.
/// Composed of:
/// - Organisms: ProductsListView
/// - Molecules: ProductFilterBar (search, price range pills, category pills, status), ProductFormDialog
/// - Atoms: ProductVariantBadge
class ProductsView extends StatefulWidget {
  final ProductManagementService productService;
  final CategoryManagementService categoryService;
  final MediaUploadService? mediaUploadService;

  const ProductsView({
    super.key,
    required this.productService,
    required this.categoryService,
    this.mediaUploadService,
  });

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  List<ProductItem> _products = [];
  List<CategoryItem> _categories = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  final Set<int> _includedCategoryIds = {};
  final Set<int> _excludedCategoryIds = {};
  final Set<PriceRangePreset> _includedPricePresets = {};
  final Set<PriceRangePreset> _excludedPricePresets = {};
  bool? _selectedActiveFilter;
  bool _isExporting = false;

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
      final results = await Future.wait([
        widget.productService.listProducts(),
        widget.categoryService.listCategories(),
      ]);

      if (mounted) {
        setState(() {
          _products = results[0] as List<ProductItem>;
          _categories = results[1] as List<CategoryItem>;
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

  List<ProductItem> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();

    return _products.where((p) {
      // 1. Search Query Filter (Product name, SKU, or slug)
      if (query.isNotEmpty) {
        final matchesName = p.productName.toLowerCase().contains(query);
        final matchesSku = p.sku.toLowerCase().contains(query);
        final matchesParentSku = p.parentSku != null && p.parentSku!.toLowerCase().contains(query);
        final matchesSlug = p.slug.toLowerCase().contains(query);
        if (!matchesName && !matchesSku && !matchesParentSku && !matchesSlug) {
          return false;
        }
      }

      // 2. Category Pill Filter (AND logic for multi-selected, NOT logic for excluded)
      if (_includedCategoryIds.isNotEmpty) {
        final productCatIds = p.categories.map((c) => c.id).toSet();
        // Item must have ALL selected categories (AND logic)
        final hasAllIncluded = _includedCategoryIds.every((id) => productCatIds.contains(id));
        if (!hasAllIncluded) {
          return false;
        }
      }
      if (_excludedCategoryIds.isNotEmpty) {
        final productCatIds = p.categories.map((c) => c.id).toSet();
        // Item must NOT have any of the excluded categories
        final hasAnyExcluded = _excludedCategoryIds.any((id) => productCatIds.contains(id));
        if (hasAnyExcluded) {
          return false;
        }
      }

      // 3. Price Range Preset Filter
      if (_includedPricePresets.isNotEmpty) {
        final price = p.effectivePrice;
        final matchesAnyIncluded = _includedPricePresets.any((preset) => preset.matches(price));
        if (!matchesAnyIncluded) {
          return false;
        }
      }
      if (_excludedPricePresets.isNotEmpty) {
        final price = p.effectivePrice;
        final matchesAnyExcluded = _excludedPricePresets.any((preset) => preset.matches(price));
        if (matchesAnyExcluded) {
          return false;
        }
      }

      // 4. Active Status Filter
      if (_selectedActiveFilter != null) {
        if (p.isActive != _selectedActiveFilter) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _toggleCategory(int catId) {
    setState(() {
      if (_includedCategoryIds.contains(catId)) {
        // State 2 -> State 3: from selected to filter out (except)
        _includedCategoryIds.remove(catId);
        _excludedCategoryIds.add(catId);
      } else if (_excludedCategoryIds.contains(catId)) {
        // State 3 -> State 1: from filter out to not selected
        _excludedCategoryIds.remove(catId);
      } else {
        // State 1 -> State 2: from not selected to selected
        _includedCategoryIds.add(catId);
      }
    });
  }

  void _togglePricePreset(PriceRangePreset preset) {
    setState(() {
      if (_includedPricePresets.contains(preset)) {
        // State 2 -> State 3: from selected to filter out (except)
        _includedPricePresets.remove(preset);
        _excludedPricePresets.add(preset);
      } else if (_excludedPricePresets.contains(preset)) {
        // State 3 -> State 1: from filter out to not selected
        _excludedPricePresets.remove(preset);
      } else {
        // State 1 -> State 2: from not selected to selected
        _includedPricePresets.add(preset);
      }
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _includedCategoryIds.clear();
      _excludedCategoryIds.clear();
      _includedPricePresets.clear();
      _excludedPricePresets.clear();
      _selectedActiveFilter = null;
    });
  }

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    try {
      await widget.productService.updateStatus(id, !currentStatus);
      _loadData();
    } catch (e) {
      _showSnackbar('Failed to update status: $e');
    }
  }

  Future<void> _deleteProduct(String id, String name) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteProduct),
        content: Text(l10n.deleteProductConfirmMsg(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.productService.deleteProduct(id);
        _showSnackbar(l10n.productDeletedSuccess);
        _loadData();
      } catch (e) {
        _showSnackbar('Cannot delete product: $e');
      }
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ProductFormDialog(
        product: null,
        allProducts: _products,
        categories: _categories,
        productService: widget.productService,
        mediaUploadService: widget.mediaUploadService,
        onSaved: _loadData,
      ),
    );
  }

  Future<void> _exportCsv() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final l10n = context.l10n;
    try {
      final query = _searchController.text.trim();
      final csv = await widget.productService.exportProductsCsv(
        search: query.isNotEmpty ? query : null,
        isActive: _selectedActiveFilter,
      );
      downloadFile(filename: 'products.csv', content: csv);
      _showSnackbar(l10n.exportCsvSuccess);
    } catch (e) {
      _showSnackbar('${l10n.exportCsvFailed}: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showEditDialog(ProductItem product) {
    showDialog(
      context: context,
      builder: (ctx) => ProductFormDialog(
        product: product,
        allProducts: _products,
        categories: _categories,
        productService: widget.productService,
        mediaUploadService: widget.mediaUploadService,
        onSaved: _loadData,
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
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Screen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.productsManagement,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.refreshProducts,
              ),
            ],
          ),
          const SizedBox(height: JoppeSpacing.md),

          // Search, Price Range & Category Filter Bar
          Card(
            elevation: 0,
            color: cs.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(JoppeShapes.medium),
              side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(JoppeSpacing.md),
              child: ProductFilterBar(
                searchController: _searchController,
                categories: _categories,
                includedCategoryIds: _includedCategoryIds,
                excludedCategoryIds: _excludedCategoryIds,
                includedPricePresets: _includedPricePresets,
                excludedPricePresets: _excludedPricePresets,
                selectedActiveFilter: _selectedActiveFilter,
                onToggleCategory: _toggleCategory,
                onTogglePricePreset: _togglePricePreset,
                onSelectStatus: (val) => setState(() => _selectedActiveFilter = val),
                onClearAllCategories: () => setState(() {
                  _includedCategoryIds.clear();
                  _excludedCategoryIds.clear();
                }),
                onClearAllPrices: () => setState(() {
                  _includedPricePresets.clear();
                  _excludedPricePresets.clear();
                }),
                onSearchChanged: () => setState(() {}),
                onReset: _resetFilters,
                onAddNewProduct: _showCreateDialog,
                onExportCsv: _isExporting ? null : _exportCsv,
              ),
            ),
          ),
          const SizedBox(height: JoppeSpacing.md),

          // Error banner
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: JoppeSpacing.md),
              child: MaterialBanner(
                content: Text(_error!),
                backgroundColor: cs.errorContainer,
                contentTextStyle: TextStyle(color: cs.onErrorContainer),
                actions: [
                  TextButton(
                    onPressed: _loadData,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ProductsListView(
                    products: _filteredProducts,
                    onEditProduct: _showEditDialog,
                    onToggleStatus: _toggleStatus,
                    onDeleteProduct: _deleteProduct,
                  ),
          ),
        ],
      ),
    );
  }
}
