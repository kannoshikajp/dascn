import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../localization/dashboard_localizations.dart';
import '../utils/file_download_helper.dart';
import 'categories/atoms/category_action_menu.dart';
import 'categories/atoms/category_kpi_card.dart';
import 'categories/atoms/category_status_badge.dart';
import 'categories/molecules/category_filter_bar.dart';
import 'categories/molecules/category_form_dialog.dart';
import 'categories/organisms/category_kpi_row.dart';
import 'categories/organisms/category_table_view.dart';
import 'categories/organisms/category_tree_view.dart';

export 'categories/atoms/category_action_menu.dart';
export 'categories/atoms/category_kpi_card.dart';
export 'categories/atoms/category_status_badge.dart';
export 'categories/molecules/category_filter_bar.dart';
export 'categories/molecules/category_form_dialog.dart';
export 'categories/organisms/category_kpi_row.dart';
export 'categories/organisms/category_table_view.dart';
export 'categories/organisms/category_tree_view.dart';

/// Screen: Category management view following Atomic Design principles.
/// Composed of:
/// - Organisms: CategoryKpiRow, CategoryTreeView, CategoryTableView
/// - Molecules: CategoryFilterBar, CategoryFormDialog
/// - Atoms: CategoryKpiCard, CategoryStatusBadge
class CategoriesView extends StatefulWidget {
  final CategoryManagementService categoryService;
  final MediaUploadService? mediaUploadService;

  const CategoriesView({
    super.key,
    required this.categoryService,
    this.mediaUploadService,
  });

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final TextEditingController _searchController = TextEditingController();
  List<CategoryItem> _flatCategories = [];
  List<CategoryNode> _treeNodes = [];
  bool _isLoading = true;
  String? _error;
  bool? _selectedActiveFilter;
  CategoryHierarchyFilter _selectedHierarchyFilter = CategoryHierarchyFilter.all;
  int _selectedViewIndex = 0; // 0 = Tree, 1 = List
  bool? _expandAll;
  int _expansionVersion = 0;
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
      final query = _searchController.text.trim();
      final results = await Future.wait([
        widget.categoryService.listCategories(
          search: query.isEmpty ? null : query,
          isActive: _selectedActiveFilter,
        ),
        widget.categoryService.listCategoryTree(
          isActive: _selectedActiveFilter,
        ),
      ]);

      if (mounted) {
        setState(() {
          _flatCategories = results[0] as List<CategoryItem>;
          _treeNodes = results[1] as List<CategoryNode>;
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

  List<CategoryItem> get _filteredFlatCategories {
    return _flatCategories.where((c) {
      // Hierarchy filter
      if (_selectedHierarchyFilter == CategoryHierarchyFilter.rootOnly && c.parentId != null) {
        return false;
      }
      if (_selectedHierarchyFilter == CategoryHierarchyFilter.subOnly && c.parentId == null) {
        return false;
      }
      return true;
    }).toList();
  }

  List<CategoryNode> get _filteredTreeNodes {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty && _selectedHierarchyFilter == CategoryHierarchyFilter.all) {
      return _treeNodes;
    }

    return _filterTreeNodesRecursive(_treeNodes, query);
  }

  List<CategoryNode> _filterTreeNodesRecursive(List<CategoryNode> nodes, String query) {
    final result = <CategoryNode>[];

    for (final node in nodes) {
      final matchesQuery = query.isEmpty ||
          node.categoryName.toLowerCase().contains(query) ||
          node.slug.toLowerCase().contains(query);

      final filteredChildren = _filterTreeNodesRecursive(node.children, query);

      if (matchesQuery || filteredChildren.isNotEmpty) {
        result.add(
          CategoryNode(
            id: node.id,
            parentId: node.parentId,
            categoryName: node.categoryName,
            slug: node.slug,
            iconUrl: node.iconUrl,
            isActive: node.isActive,
            productCount: node.productCount,
            children: filteredChildren,
          ),
        );
      }
    }

    return result;
  }

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    final l10n = context.l10n;
    try {
      await widget.categoryService.updateStatus(id, !currentStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.categoryStatusUpdated)),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdateStatus(e))),
        );
      }
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCategoryTitle),
        content: Text(l10n.deleteCategoryConfirmMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
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
        await widget.categoryService.deleteCategory(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.categoryDeletedSuccess)),
          );
        }
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.cannotDeleteCategory}: $e')),
          );
        }
      }
    }
  }

  void _showFormDialog({CategoryItem? category, int? defaultParentId}) {
    showDialog(
      context: context,
      builder: (ctx) => CategoryFormDialog(
        category: category,
        defaultParentId: defaultParentId,
        allCategories: _flatCategories,
        categoryService: widget.categoryService,
        mediaUploadService: widget.mediaUploadService,
        onSuccess: _loadData,
      ),
    );
  }

  void _onEditCategoryFromNode(CategoryNode node) {
    final item = _flatCategories.firstWhere(
      (c) => c.id == node.id,
      orElse: () => CategoryItem(
        id: node.id,
        parentId: node.parentId,
        categoryName: node.categoryName,
        slug: node.slug,
        iconUrl: node.iconUrl,
        isActive: node.isActive,
        productCount: node.productCount,
      ),
    );
    _showFormDialog(category: item);
  }

  Future<void> _exportCsv() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    final l10n = context.l10n;
    try {
      final query = _searchController.text.trim();
      final csv = await widget.categoryService.exportCategoriesCsv(
        search: query.isNotEmpty ? query : null,
        isActive: _selectedActiveFilter,
      );
      downloadFile(filename: 'categories.csv', content: csv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportCsvSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.exportCsvFailed}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedActiveFilter = null;
      _selectedHierarchyFilter = CategoryHierarchyFilter.all;
      _expandAll = null;
      _expansionVersion++;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. KPI Overview Row
          CategoryKpiRow(categories: _flatCategories),
          const SizedBox(height: JoppeSpacing.md),

          // 2. Filter Toolbar Molecule
          CategoryFilterBar(
            searchController: _searchController,
            selectedActiveFilter: _selectedActiveFilter,
            selectedHierarchyFilter: _selectedHierarchyFilter,
            selectedViewIndex: _selectedViewIndex,
            onSelectStatus: (val) {
              setState(() => _selectedActiveFilter = val);
              _loadData();
            },
            onSelectHierarchy: (val) {
              setState(() => _selectedHierarchyFilter = val);
            },
            onSelectViewMode: (val) {
              setState(() => _selectedViewIndex = val);
            },
            onSearchChanged: _loadData,
            onReset: _resetFilters,
            onExportCsv: _isExporting ? null : _exportCsv,
            onAddCategory: () => _showFormDialog(),
            onExpandAll: () => setState(() {
              _expandAll = true;
              _expansionVersion++;
            }),
            onCollapseAll: () => setState(() {
              _expandAll = false;
              _expansionVersion++;
            }),
          ),
          const SizedBox(height: JoppeSpacing.md),

          // 3. Content Display (Tree vs Flat Table)
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
                              onPressed: _loadData,
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : _selectedViewIndex == 0
                        ? CategoryTreeView(
                            treeNodes: _filteredTreeNodes,
                            onAddSubcategory: (parentId) => _showFormDialog(defaultParentId: parentId),
                            onToggleStatus: _toggleStatus,
                            onEditCategory: _onEditCategoryFromNode,
                            onDeleteCategory: _deleteCategory,
                            expandAll: _expandAll,
                            expansionVersion: _expansionVersion,
                          )
                        : CategoryTableView(
                            categories: _filteredFlatCategories,
                            onAddSubcategory: (parentId) => _showFormDialog(defaultParentId: parentId),
                            onToggleStatus: _toggleStatus,
                            onEditCategory: (cat) => _showFormDialog(category: cat),
                            onDeleteCategory: _deleteCategory,
                          ),
          ),
        ],
      ),
    );
  }
}
