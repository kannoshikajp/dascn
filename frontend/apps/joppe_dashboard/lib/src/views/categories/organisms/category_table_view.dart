import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/category_action_menu.dart';
import '../atoms/category_status_badge.dart';

/// Organism: Tabular data view displaying flat category items with thumbnail,
/// parent hierarchy breadcrumbs, product metrics, and actions.
class CategoryTableView extends StatefulWidget {
  final List<CategoryItem> categories;
  final ValueChanged<int> onAddSubcategory;
  final void Function(int id, bool currentStatus) onToggleStatus;
  final ValueChanged<CategoryItem> onEditCategory;
  final void Function(int id, String name) onDeleteCategory;

  const CategoryTableView({
    super.key,
    required this.categories,
    required this.onAddSubcategory,
    required this.onToggleStatus,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  @override
  State<CategoryTableView> createState() => _CategoryTableViewState();
}

class _CategoryTableViewState extends State<CategoryTableView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const defaultApiUrl = 'http://localhost:8080';
    if (url.startsWith('/')) return '$defaultApiUrl$url';
    return '$defaultApiUrl/$url';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (widget.categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.category_outlined, size: 54, color: cs.onSurfaceVariant.withAlpha(120)),
              const SizedBox(height: JoppeSpacing.sm),
              Text(
                l10n.noCategoriesFound,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: widget.categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: JoppeSpacing.xs),
      itemBuilder: (context, idx) {
        final c = widget.categories[idx];

        return Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(JoppeShapes.medium),
            side: BorderSide(color: cs.outlineVariant.withAlpha(70)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.sm, vertical: JoppeSpacing.xs),
            child: ListTile(
              leading: _buildLeadingAvatar(c, cs),
              title: Row(
                children: [
                  if (c.parentName != null) ...[
                    Text(
                      '${c.parentName} > ',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  Text(
                    c.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: JoppeSpacing.xs),
                  Text(
                    '(${c.slug})',
                    style: TextStyle(
                      color: cs.onSurfaceVariant.withAlpha(180),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Text(
                      l10n.categorySummary(c.productCount, c.childCount),
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                    const SizedBox(width: JoppeSpacing.md),
                    CategoryStatusBadge(
                      isActive: c.isActive,
                      onToggle: () => widget.onToggleStatus(c.id, c.isActive),
                    ),
                  ],
                ),
              ),
              trailing: CategoryActionMenu(
                categoryId: c.id,
                categoryName: c.categoryName,
                isActive: c.isActive,
                onAddSubcategory: widget.onAddSubcategory,
                onEdit: () => widget.onEditCategory(c),
                onToggleStatus: () => widget.onToggleStatus(c.id, c.isActive),
                onDelete: () => widget.onDeleteCategory(c.id, c.categoryName),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeadingAvatar(CategoryItem c, ColorScheme cs) {
    if (c.iconUrl != null && c.iconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(JoppeShapes.small),
        child: Image.network(
          _resolveImageUrl(c.iconUrl!),
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _defaultAvatar(c, cs),
        ),
      );
    }
    return _defaultAvatar(c, cs);
  }

  Widget _defaultAvatar(CategoryItem c, ColorScheme cs) {
    final isRoot = c.parentId == null;
    final color = c.isActive ? cs.primary : cs.onSurfaceVariant;

    return CircleAvatar(
      radius: 20,
      backgroundColor: c.isActive ? cs.primaryContainer : cs.surfaceContainerHigh,
      child: Icon(
        isRoot ? Icons.folder_rounded : Icons.subdirectory_arrow_right_rounded,
        color: c.isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}
