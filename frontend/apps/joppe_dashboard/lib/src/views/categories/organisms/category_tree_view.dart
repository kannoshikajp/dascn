import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/category_action_menu.dart';
import '../atoms/category_status_badge.dart';

/// Organism: Hierarchical tree view displaying nested category nodes with
/// expandable branches, chevron collapse/expand indicators, visual guide indentation,
/// product counts, and three-dot action menu.
class CategoryTreeView extends StatelessWidget {
  final List<CategoryNode> treeNodes;
  final ValueChanged<int> onAddSubcategory;
  final void Function(int id, bool currentStatus) onToggleStatus;
  final ValueChanged<CategoryNode> onEditCategory;
  final void Function(int id, String name) onDeleteCategory;
  final bool? expandAll;
  final int expansionVersion;

  const CategoryTreeView({
    super.key,
    required this.treeNodes,
    required this.onAddSubcategory,
    required this.onToggleStatus,
    required this.onEditCategory,
    required this.onDeleteCategory,
    this.expandAll,
    this.expansionVersion = 0,
  });

  String _resolveImageUrl(String url) => ApiClient.resolveUrl(url);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (treeNodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_tree_outlined, size: 54, color: cs.onSurfaceVariant.withAlpha(120)),
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

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(JoppeShapes.medium),
        side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(JoppeSpacing.sm),
        itemCount: treeNodes.length,
        itemBuilder: (context, idx) => _buildItemTile(treeNodes[idx], 0, cs, l10n),
      ),
    );
  }

  Widget _buildItemTile(CategoryNode node, int depth, ColorScheme cs, DashboardLocalizations l10n) {
    return _CategoryTreeItemTile(
      node: node,
      depth: depth,
      colorScheme: cs,
      l10n: l10n,
      expandAll: expandAll,
      expansionVersion: expansionVersion,
      onAddSubcategory: onAddSubcategory,
      onToggleStatus: onToggleStatus,
      onEditCategory: onEditCategory,
      onDeleteCategory: onDeleteCategory,
      buildChild: (child, childDepth) => _buildItemTile(child, childDepth, cs, l10n),
      resolveImageUrl: _resolveImageUrl,
    );
  }
}

class _CategoryTreeItemTile extends StatefulWidget {
  final CategoryNode node;
  final int depth;
  final ColorScheme colorScheme;
  final DashboardLocalizations l10n;
  final bool? expandAll;
  final int expansionVersion;
  final ValueChanged<int> onAddSubcategory;
  final void Function(int id, bool currentStatus) onToggleStatus;
  final ValueChanged<CategoryNode> onEditCategory;
  final void Function(int id, String name) onDeleteCategory;
  final Widget Function(CategoryNode node, int depth) buildChild;
  final String Function(String url) resolveImageUrl;

  const _CategoryTreeItemTile({
    required this.node,
    required this.depth,
    required this.colorScheme,
    required this.l10n,
    required this.expandAll,
    required this.expansionVersion,
    required this.onAddSubcategory,
    required this.onToggleStatus,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.buildChild,
    required this.resolveImageUrl,
  });

  @override
  State<_CategoryTreeItemTile> createState() => _CategoryTreeItemTileState();
}

class _CategoryTreeItemTileState extends State<_CategoryTreeItemTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expandAll == null ? widget.depth < 1 : widget.expandAll!;
  }

  @override
  void didUpdateWidget(covariant _CategoryTreeItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expandAll != widget.expandAll ||
        oldWidget.expansionVersion != widget.expansionVersion) {
      _isExpanded = widget.expandAll == null ? widget.depth < 1 : widget.expandAll!;
    }
  }

  Widget _buildLeadingIcon(CategoryNode node, int depth, ColorScheme cs) {
    if (node.iconUrl != null && node.iconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          widget.resolveImageUrl(node.iconUrl!),
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _defaultIcon(node, depth, cs),
        ),
      );
    }
    return _defaultIcon(node, depth, cs);
  }

  Widget _defaultIcon(CategoryNode node, int depth, ColorScheme cs) {
    final iconData = depth == 0
        ? Icons.folder_open_rounded
        : depth == 1
            ? Icons.subdirectory_arrow_right_rounded
            : Icons.label_important_outline_rounded;
    final iconColor = node.isActive ? cs.primary : cs.onSurfaceVariant.withAlpha(160);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: iconColor.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(iconData, color: iconColor, size: 17),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final depth = widget.depth;
    final colorScheme = widget.colorScheme;
    final l10n = widget.l10n;
    final hasChildren = node.children.isNotEmpty;

    final titleRow = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: JoppeSpacing.xs,
      runSpacing: 2,
      children: [
        Text(
          node.categoryName,
          style: TextStyle(
            fontWeight: depth == 0 ? FontWeight.bold : FontWeight.w600,
            fontSize: depth == 0 ? 15 : 13,
            color: node.isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '/${node.slug}',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant.withAlpha(180),
            fontFamily: 'monospace',
          ),
        ),
        Chip(
          label: Text(
            l10n.categoryProductsCount(node.productCount),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
        ),
        if (hasChildren) ...[
          Chip(
            label: Text(
              l10n.categorySubcount(node.children.length),
              style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.blue.withAlpha(20),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: Colors.blue.withAlpha(60)),
          ),
        ],
        CategoryStatusBadge(
          isActive: node.isActive,
          onToggle: () => widget.onToggleStatus(node.id, node.isActive),
        ),
      ],
    );

    final actionMenu = CategoryActionMenu(
      categoryId: node.id,
      categoryName: node.categoryName,
      isActive: node.isActive,
      onAddSubcategory: widget.onAddSubcategory,
      onEdit: () => widget.onEditCategory(node),
      onToggleStatus: () => widget.onToggleStatus(node.id, node.isActive),
      onDelete: () => widget.onDeleteCategory(node.id, node.categoryName),
    );

    if (hasChildren) {
      final leadingWithChevron = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isExpanded
                ? Icons.keyboard_arrow_down_rounded
                : Icons.keyboard_arrow_right_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          _buildLeadingIcon(node, depth, colorScheme),
        ],
      );

      final trailingWithChevron = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          actionMenu,
          const SizedBox(width: 4),
          AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );

      return Padding(
        padding: EdgeInsets.only(left: depth * 20.0),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('tree_node_${node.id}_v${widget.expansionVersion}_${widget.expandAll}'),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _isExpanded = expanded);
            },
            leading: leadingWithChevron,
            title: titleRow,
            trailing: trailingWithChevron,
            tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            childrenPadding: EdgeInsets.zero,
            children: node.children
                .map((child) => widget.buildChild(child, depth + 1))
                .toList(),
          ),
        ),
      );
    }

    // Leaf category without subcategories: align with parent using spacer
    final leadingLeaf = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 24),
        _buildLeadingIcon(node, depth, colorScheme),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0),
      child: ListTile(
        leading: leadingLeaf,
        title: titleRow,
        trailing: actionMenu,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}
