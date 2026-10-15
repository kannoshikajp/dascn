import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

class ProductsView extends StatefulWidget {
  final ProductManagementService productService;
  final CategoryManagementService categoryService;

  const ProductsView({
    super.key,
    required this.productService,
    required this.categoryService,
  });

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  List<ProductItem> _products = [];
  List<CategoryItem> _categories = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  int? _selectedCategoryFilter;
  bool? _selectedActiveFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.productService.listProducts(
          search: _searchQuery.isEmpty ? null : _searchQuery,
          categoryId: _selectedCategoryFilter,
          isActive: _selectedActiveFilter,
        ),
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

  Future<void> _toggleStatus(String id, bool currentStatus) async {
    try {
      await widget.productService.updateStatus(id, !currentStatus);
      _loadData();
    } catch (e) {
      _showSnackbar('Failed to update status: $e');
    }
  }

  Future<void> _deleteProduct(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"? This cannot be undone.'),
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
        await widget.productService.deleteProduct(id);
        _showSnackbar('Product deleted');
        _loadData();
      } catch (e) {
        _showSnackbar('Cannot delete product: $e');
      }
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final shortDescCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final warrantyCtrl = TextEditingController(text: '12');
    final thumbCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final listPriceCtrl = TextEditingController(text: '0');
    final salePriceCtrl = TextEditingController(text: '0');
    final stockCtrl = TextEditingController(text: '10');

    Set<int> selectedCategoryIds = {};
    int? primaryCategoryId;
    bool isActive = true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Product'),
          content: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        hintText: 'e.g. Laptop ASUS ROG Strix G16',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
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
                      decoration: const InputDecoration(labelText: 'URL Slug'),
                    ),
                    const SizedBox(height: JoppeSpacing.md),

                    // Multi-Category Selector Section
                    Text(
                      'Categories (Select one or multiple)',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: JoppeSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(JoppeSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(ctx).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: _categories.isEmpty
                          ? const Center(child: Text('No categories available.'))
                          : ListView(
                              shrinkWrap: true,
                              children: _categories.map((cat) {
                                final isSelected = selectedCategoryIds.contains(cat.id);
                                final isPrimary = primaryCategoryId == cat.id;

                                return CheckboxListTile(
                                  dense: true,
                                  title: Row(
                                    children: [
                                      Text(cat.parentName != null ? '${cat.parentName} > ${cat.categoryName}' : cat.categoryName),
                                      if (isSelected) ...[
                                        const SizedBox(width: JoppeSpacing.xs),
                                        GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              primaryCategoryId = cat.id;
                                            });
                                          },
                                          child: Chip(
                                            label: Text(
                                              isPrimary ? 'Primary' : 'Make Primary',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isPrimary ? Theme.of(ctx).colorScheme.onPrimary : null,
                                              ),
                                            ),
                                            backgroundColor: isPrimary ? Theme.of(ctx).colorScheme.primary : null,
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedCategoryIds.add(cat.id);
                                        primaryCategoryId ??= cat.id;
                                      } else {
                                        selectedCategoryIds.remove(cat.id);
                                        if (primaryCategoryId == cat.id) {
                                          primaryCategoryId = selectedCategoryIds.isNotEmpty ? selectedCategoryIds.first : null;
                                        }
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: JoppeSpacing.md),

                    // Price and Stock
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: listPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'List Price (VND)'),
                          ),
                        ),
                        const SizedBox(width: JoppeSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: salePriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Sale Price (VND)'),
                          ),
                        ),
                        const SizedBox(width: JoppeSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Initial Stock'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: skuCtrl,
                            decoration: const InputDecoration(labelText: 'Initial SKU (optional)'),
                          ),
                        ),
                        const SizedBox(width: JoppeSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: warrantyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Warranty (Months)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: thumbCtrl,
                      decoration: const InputDecoration(labelText: 'Thumbnail Image URL (optional)'),
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: shortDescCtrl,
                      decoration: const InputDecoration(labelText: 'Short Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    SwitchListTile(
                      title: const Text('Product Active'),
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
                  await widget.productService.createProduct(
                    productName: nameCtrl.text.trim(),
                    slug: slugCtrl.text.trim().isEmpty ? null : slugCtrl.text.trim(),
                    categoryIds: selectedCategoryIds.toList(),
                    primaryCategoryId: primaryCategoryId,
                    shortDescription: shortDescCtrl.text.trim().isEmpty ? null : shortDescCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    warrantyMonths: int.tryParse(warrantyCtrl.text),
                    thumbnailUrl: thumbCtrl.text.trim().isEmpty ? null : thumbCtrl.text.trim(),
                    isActive: isActive,
                    sku: skuCtrl.text.trim().isEmpty ? null : skuCtrl.text.trim(),
                    listPrice: double.tryParse(listPriceCtrl.text),
                    salePrice: double.tryParse(salePriceCtrl.text),
                    stockQuantity: int.tryParse(stockCtrl.text),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnackbar('Product created successfully');
                  _loadData();
                } catch (e) {
                  _showSnackbar('Error creating product: $e');
                }
              },
              child: const Text('Create Product'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(ProductItem product) {
    final nameCtrl = TextEditingController(text: product.productName);
    final slugCtrl = TextEditingController(text: product.slug);
    final shortDescCtrl = TextEditingController(text: product.shortDescription ?? '');
    final descCtrl = TextEditingController(text: product.description ?? '');
    final warrantyCtrl = TextEditingController(text: product.warrantyMonths.toString());
    final thumbCtrl = TextEditingController(text: product.thumbnailUrl ?? '');

    Set<int> selectedCategoryIds = product.categories.map((c) => c.id).toSet();
    int? primaryCategoryId = product.categories.where((c) => c.isPrimary).map((c) => c.id).firstOrNull ??
        (selectedCategoryIds.isNotEmpty ? selectedCategoryIds.first : null);
    bool isActive = product.isActive;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit "${product.productName}"'),
          content: SizedBox(
            width: 600,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: slugCtrl,
                      decoration: const InputDecoration(labelText: 'URL Slug'),
                    ),
                    const SizedBox(height: JoppeSpacing.md),

                    // Multi-Category Selector Section
                    Text(
                      'Categories (Select one or multiple)',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: JoppeSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(JoppeSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(ctx).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: _categories.isEmpty
                          ? const Center(child: Text('No categories available.'))
                          : ListView(
                              shrinkWrap: true,
                              children: _categories.map((cat) {
                                final isSelected = selectedCategoryIds.contains(cat.id);
                                final isPrimary = primaryCategoryId == cat.id;

                                return CheckboxListTile(
                                  dense: true,
                                  title: Row(
                                    children: [
                                      Text(cat.parentName != null ? '${cat.parentName} > ${cat.categoryName}' : cat.categoryName),
                                      if (isSelected) ...[
                                        const SizedBox(width: JoppeSpacing.xs),
                                        GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              primaryCategoryId = cat.id;
                                            });
                                          },
                                          child: Chip(
                                            label: Text(
                                              isPrimary ? 'Primary' : 'Make Primary',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isPrimary ? Theme.of(ctx).colorScheme.onPrimary : null,
                                              ),
                                            ),
                                            backgroundColor: isPrimary ? Theme.of(ctx).colorScheme.primary : null,
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  value: isSelected,
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedCategoryIds.add(cat.id);
                                        primaryCategoryId ??= cat.id;
                                      } else {
                                        selectedCategoryIds.remove(cat.id);
                                        if (primaryCategoryId == cat.id) {
                                          primaryCategoryId = selectedCategoryIds.isNotEmpty ? selectedCategoryIds.first : null;
                                        }
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: JoppeSpacing.md),
                    TextFormField(
                      controller: warrantyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Warranty (Months)'),
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: thumbCtrl,
                      decoration: const InputDecoration(labelText: 'Thumbnail Image URL'),
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: shortDescCtrl,
                      decoration: const InputDecoration(labelText: 'Short Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Full Description'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    SwitchListTile(
                      title: const Text('Product Active'),
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
                  await widget.productService.updateProduct(
                    id: product.id,
                    productName: nameCtrl.text.trim(),
                    slug: slugCtrl.text.trim().isEmpty ? null : slugCtrl.text.trim(),
                    categoryIds: selectedCategoryIds.toList(),
                    primaryCategoryId: primaryCategoryId,
                    shortDescription: shortDescCtrl.text.trim().isEmpty ? null : shortDescCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    warrantyMonths: int.tryParse(warrantyCtrl.text),
                    thumbnailUrl: thumbCtrl.text.trim().isEmpty ? null : thumbCtrl.text.trim(),
                    isActive: isActive,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showSnackbar('Product updated successfully');
                  _loadData();
                } catch (e) {
                  _showSnackbar('Error updating product: $e');
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price <= 0) return '0 ₫';
    final str = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} ₫';
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
                        width: 240,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search product, SKU...',
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
                      DropdownButton<int?>(
                        value: _selectedCategoryFilter,
                        hint: const Text('All Categories'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Categories')),
                          ..._categories.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.categoryName),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedCategoryFilter = val);
                          _loadData();
                        },
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
                  FilledButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
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
                    : _products.isEmpty
                        ? const Center(child: Text('No products found.'))
                        : ListView.separated(
                            itemCount: _products.length,
                            separatorBuilder: (context, index) => const SizedBox(height: JoppeSpacing.xs),
                            itemBuilder: (context, idx) {
                              final p = _products[idx];
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(JoppeSpacing.sm),
                                  child: Row(
                                    children: [
                                      // Thumbnail
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 56,
                                          height: 56,
                                          color: colorScheme.surfaceContainerHigh,
                                          child: p.thumbnailUrl != null && p.thumbnailUrl!.isNotEmpty
                                              ? Image.network(
                                                  p.thumbnailUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (ctx, e, s) => const Icon(Icons.laptop),
                                                )
                                              : const Icon(Icons.laptop),
                                        ),
                                      ),
                                      const SizedBox(width: JoppeSpacing.md),

                                      // Product Details & Categories
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    p.productName,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: JoppeSpacing.sm),
                                                Text(
                                                  _formatPrice(p.minPrice),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.primary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '/${p.slug} • ${p.variants.isNotEmpty ? p.variants.first.sku : 'No SKU'}',
                                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                                            ),
                                            const SizedBox(height: 4),

                                            // Multiple category tags!
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 2,
                                              children: p.categories.map((c) {
                                                return Chip(
                                                  label: Text(
                                                    c.isPrimary ? '${c.categoryName} ★' : c.categoryName,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: c.isPrimary ? FontWeight.bold : FontWeight.normal,
                                                    ),
                                                  ),
                                                  backgroundColor: c.isPrimary
                                                      ? colorScheme.primaryContainer
                                                      : colorScheme.surfaceContainerHighest,
                                                  padding: EdgeInsets.zero,
                                                  visualDensity: VisualDensity.compact,
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: JoppeSpacing.md),

                                      // Stock badge
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Chip(
                                            label: Text(
                                              p.totalStock > 0 ? '${p.totalStock} in stock' : 'Out of stock',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: p.totalStock > 0
                                                    ? colorScheme.onSecondaryContainer
                                                    : colorScheme.onErrorContainer,
                                              ),
                                            ),
                                            backgroundColor: p.totalStock > 0
                                                ? colorScheme.secondaryContainer
                                                : colorScheme.errorContainer,
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: JoppeSpacing.md),

                                      // Active Switch & Action buttons
                                      Switch(
                                        value: p.isActive,
                                        onChanged: (_) => _toggleStatus(p.id, p.isActive),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _showEditDialog(p),
                                        tooltip: 'Edit Product',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        color: colorScheme.error,
                                        onPressed: () => _deleteProduct(p.id, p.productName),
                                        tooltip: 'Delete Product',
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
