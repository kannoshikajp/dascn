import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../widgets/image_upload_field.dart';

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

class _CategoriesViewState extends State<CategoriesView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CategoryItem> _flatCategories = [];
  List<CategoryNode> _treeNodes = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  bool? _selectedActiveFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final flat = await widget.categoryService.listCategories(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        isActive: _selectedActiveFilter,
      );
      final tree = await widget.categoryService.listCategoryTree(
        isActive: _selectedActiveFilter,
      );

      if (mounted) {
        setState(() {
          _flatCategories = flat;
          _treeNodes = tree;
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

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    try {
      await widget.categoryService.updateStatus(id, !currentStatus);
      _loadData();
    } catch (e) {
      _showSnackbar('Failed to update status: $e');
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete category "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.categoryService.deleteCategory(id);
        _showSnackbar('Category deleted');
        _loadData();
      } catch (e) {
        _showSnackbar('Cannot delete category: $e');
      }
    }
  }

  void _showCreateDialog({int? defaultParentId}) {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final iconCtrl = TextEditingController();
    int? selectedParent = defaultParentId;
    bool isActive = true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Category'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        hintText: 'e.g. Laptop, Gaming, Mouse',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      onChanged: (v) {
                        if (slugCtrl.text.isEmpty || slugCtrl.text == _slugify(nameCtrl.text)) {
                          setDialogState(() {
                            slugCtrl.text = _slugify(v);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: slugCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL Slug',
                        hintText: 'e.g. laptop-gaming',
                      ),
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedParent,
                      decoration: const InputDecoration(labelText: 'Parent Category'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('[Root Level - No Parent]')),
                        ..._flatCategories.map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.parentName != null ? '${c.parentName} > ${c.categoryName}' : c.categoryName,
                              ),
                            )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedParent = val),
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    ImageUploadField(
                      controller: iconCtrl,
                      mediaUploadService: widget.mediaUploadService,
                      label: 'Icon / Image URL (optional)',
                      folder: 'categories',
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    SwitchListTile(
                      title: const Text('Category Active'),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await widget.categoryService.createCategory(
                    parentId: selectedParent,
                    categoryName: nameCtrl.text.trim(),
                    slug: slugCtrl.text.trim().isEmpty ? null : slugCtrl.text.trim(),
                    iconUrl: iconCtrl.text.trim().isEmpty ? null : iconCtrl.text.trim(),
                    isActive: isActive,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnackbar('Category created successfully');
                  _loadData();
                } catch (e) {
                  _showSnackbar('Error creating category: $e');
                }
              },
              child: const Text('Create Category'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(CategoryItem category) {
    final nameCtrl = TextEditingController(text: category.categoryName);
    final slugCtrl = TextEditingController(text: category.slug);
    final iconCtrl = TextEditingController(text: category.iconUrl ?? '');
    int? selectedParent = category.parentId;
    bool isActive = category.isActive;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit "${category.categoryName}"'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Category Name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: slugCtrl,
                      decoration: const InputDecoration(labelText: 'URL Slug'),
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedParent,
                      decoration: const InputDecoration(labelText: 'Parent Category'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('[Root Level - No Parent]')),
                        ..._flatCategories
                            .where((c) => c.id != category.id)
                            .map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(
                                    c.parentName != null ? '${c.parentName} > ${c.categoryName}' : c.categoryName,
                                  ),
                                )),
                      ],
                      onChanged: (val) => setDialogState(() => selectedParent = val),
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    ImageUploadField(
                      controller: iconCtrl,
                      mediaUploadService: widget.mediaUploadService,
                      label: 'Icon / Image URL',
                      folder: 'categories',
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    SwitchListTile(
                      title: const Text('Category Active'),
                      value: isActive,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await widget.categoryService.updateCategory(
                    id: category.id,
                    parentId: selectedParent,
                    categoryName: nameCtrl.text.trim(),
                    slug: slugCtrl.text.trim().isEmpty ? null : slugCtrl.text.trim(),
                    iconUrl: iconCtrl.text.trim().isEmpty ? null : iconCtrl.text.trim(),
                    isActive: isActive,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnackbar('Category updated successfully');
                  _loadData();
                } catch (e) {
                  _showSnackbar('Error updating category: $e');
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  String _slugify(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Toolbar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(JoppeSpacing.md),
              child: Wrap(
                spacing: JoppeSpacing.md,
                runSpacing: JoppeSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 260,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search categories...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            _searchQuery = val;
                            _loadData();
                          },
                        ),
                      ),
                      const SizedBox(width: JoppeSpacing.sm),
                      DropdownButton<bool?>(
                        value: _selectedActiveFilter,
                        hint: const Text('All Status'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All Status')),
                          DropdownMenuItem(value: true, child: Text('Active Only')),
                          DropdownMenuItem(value: false, child: Text('Inactive Only')),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedActiveFilter = val);
                          _loadData();
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, icon: Icon(Icons.account_tree_outlined), label: Text('Tree')),
                          ButtonSegment(value: 1, icon: Icon(Icons.table_rows_outlined), label: Text('List')),
                        ],
                        selected: {_tabController.index},
                        onSelectionChanged: (newSelection) {
                          setState(() => _tabController.index = newSelection.first);
                        },
                      ),
                      const SizedBox(width: JoppeSpacing.sm),
                      FilledButton.icon(
                        onPressed: () => _showCreateDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Category'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: JoppeSpacing.md),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _tabController.index == 0
                        ? _buildTreeView(colorScheme)
                        : _buildFlatListView(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeView(ColorScheme colorScheme) {
    if (_treeNodes.isEmpty) {
      return const Center(child: Text('No categories found.'));
    }

    return Card(
      child: ListView.builder(
        padding: const EdgeInsets.all(JoppeSpacing.sm),
        itemCount: _treeNodes.length,
        itemBuilder: (context, idx) => _buildTreeNodeTile(_treeNodes[idx], 0, colorScheme),
      ),
    );
  }

  Widget _buildTreeNodeTile(CategoryNode node, int depth, ColorScheme colorScheme) {
    final hasChildren = node.children.isNotEmpty;

    final leadingIcon = Icon(
      depth == 0
          ? Icons.folder_open
          : depth == 1
              ? Icons.subdirectory_arrow_right
              : Icons.label_important_outline,
      color: node.isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
      size: 20,
    );

    final titleRow = Row(
      children: [
        Text(
          node.categoryName,
          style: TextStyle(
            fontWeight: depth == 0 ? FontWeight.bold : FontWeight.w500,
            color: node.isActive ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: JoppeSpacing.xs),
        Text(
          '/${node.slug}',
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: JoppeSpacing.xs),
        Chip(
          label: Text('${node.productCount} products', style: const TextStyle(fontSize: 10)),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Add Subcategory',
          child: IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 18),
            onPressed: () => _showCreateDialog(defaultParentId: node.id),
          ),
        ),
        Tooltip(
          message: node.isActive ? 'Active (click to deactivate)' : 'Inactive (click to activate)',
          child: Switch(
            value: node.isActive,
            onChanged: (_) => _toggleStatus(node.id, node.isActive),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          onPressed: () {
            final item = _flatCategories.firstWhere(
              (c) => c.id == node.id,
              orElse: () => CategoryItem(
                id: node.id,
                parentId: node.parentId,
                categoryName: node.categoryName,
                slug: node.slug,
                iconUrl: node.iconUrl,
                isActive: node.isActive,
              ),
            );
            _showEditDialog(item);
          },
          tooltip: 'Edit Category',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          color: colorScheme.error,
          onPressed: () => _deleteCategory(node.id, node.categoryName),
          tooltip: 'Delete Category',
        ),
      ],
    );

    if (hasChildren) {
      return Padding(
        padding: EdgeInsets.only(left: depth * 16.0),
        child: ExpansionTile(
          initiallyExpanded: depth < 1,
          leading: leadingIcon,
          title: titleRow,
          trailing: actions,
          children: node.children
              .map((child) => _buildTreeNodeTile(child, depth + 1, colorScheme))
              .toList(),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: ListTile(
        leading: leadingIcon,
        title: titleRow,
        trailing: actions,
      ),
    );
  }

  Widget _buildFlatListView(ColorScheme colorScheme) {
    if (_flatCategories.isEmpty) {
      return const Center(child: Text('No categories found.'));
    }

    return ListView.separated(
      itemCount: _flatCategories.length,
      separatorBuilder: (context, index) => const SizedBox(height: JoppeSpacing.xs),
      itemBuilder: (context, idx) {
        final c = _flatCategories[idx];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: c.isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerHigh,
              child: Icon(
                c.parentId == null ? Icons.folder : Icons.subdirectory_arrow_right,
                color: c.isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
            title: Row(
              children: [
                if (c.parentName != null) ...[
                  Text(
                    '${c.parentName} > ',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
                Text(c.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: JoppeSpacing.xs),
                Text(
                  '(${c.slug})',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
            subtitle: Text('${c.productCount} products • ${c.childCount} subcategories'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: c.isActive,
                  onChanged: (_) => _toggleStatus(c.id, c.isActive),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditDialog(c),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: colorScheme.error,
                  onPressed: () => _deleteCategory(c.id, c.categoryName),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
