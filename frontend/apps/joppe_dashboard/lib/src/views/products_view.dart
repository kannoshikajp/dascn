import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../widgets/image_upload_field.dart';
import '../widgets/markdown_editor_field.dart';

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
            width: 750,
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
                    ImageUploadField(
                      controller: thumbCtrl,
                      mediaUploadService: widget.mediaUploadService,
                      label: 'Thumbnail Image URL (optional)',
                      folder: 'products',
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: shortDescCtrl,
                      decoration: const InputDecoration(labelText: 'Short Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    MarkdownEditorField(
                      controller: descCtrl,
                      mediaUploadService: widget.mediaUploadService,
                      label: 'Full Description (Markdown)',
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
            width: 750,
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
                    ImageUploadField(
                      controller: thumbCtrl,
                      mediaUploadService: widget.mediaUploadService,
                      label: 'Thumbnail Image URL',
                      folder: 'products',
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    TextFormField(
                      controller: shortDescCtrl,
                      decoration: const InputDecoration(labelText: 'Short Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: JoppeSpacing.sm),
                    MarkdownEditorField(
                      controller: descCtrl,
                      mediaUploadService: widget.mediaUploadService,
                      label: 'Full Description (Markdown)',
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

  void _showVariantsDialog(ProductItem product) {
    List<ProductVariantSummary> variants = List.of(product.variants);
    bool isLoadingVariants = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colorScheme = Theme.of(ctx).colorScheme;

          Future<void> reloadVariants() async {
            setDialogState(() => isLoadingVariants = true);
            try {
              final fresh = await widget.productService.listVariants(product.id);
              if (ctx.mounted) {
                setDialogState(() {
                  variants = fresh;
                  isLoadingVariants = false;
                });
              }
              _loadData();
            } catch (e) {
              if (ctx.mounted) {
                setDialogState(() => isLoadingVariants = false);
                _showSnackbar('Failed to load variants: $e');
              }
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.tune_outlined),
                const SizedBox(width: JoppeSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Variants & Hardware Specs',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        product.productName,
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Variant'),
                  onPressed: () => _showVariantFormDialog(
                    product: product,
                    onSaved: reloadVariants,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 750,
              height: 480,
              child: isLoadingVariants
                  ? const Center(child: CircularProgressIndicator())
                  : variants.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.layers_clear_outlined, size: 48, color: colorScheme.outline),
                              const SizedBox(height: JoppeSpacing.sm),
                              const Text('No variants found for this product.'),
                              const SizedBox(height: JoppeSpacing.sm),
                              FilledButton.tonalIcon(
                                icon: const Icon(Icons.add),
                                label: const Text('Create First Variant'),
                                onPressed: () => _showVariantFormDialog(
                                  product: product,
                                  onSaved: reloadVariants,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: variants.length,
                          separatorBuilder: (_, _) => const SizedBox(height: JoppeSpacing.sm),
                          itemBuilder: (ctx, index) {
                            final v = variants[index];
                            final attrs = v.parsedAttributes;

                            return Card(
                              elevation: 0,
                              color: colorScheme.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: colorScheme.outlineVariant),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(JoppeSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondaryContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            v.sku,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: JoppeSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            v.variantName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        Text(
                                          _formatPrice(v.salePrice > 0 ? v.salePrice : v.listPrice),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: JoppeSpacing.sm),
                                        Chip(
                                          label: Text(
                                            '${v.availableQuantity} available (${v.quantityOnHand} stock)',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const SizedBox(width: JoppeSpacing.xs),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          tooltip: 'Edit Variant',
                                          onPressed: () => _showVariantFormDialog(
                                            product: product,
                                            variant: v,
                                            onSaved: reloadVariants,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          color: colorScheme.error,
                                          tooltip: 'Delete Variant',
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (dCtx) => AlertDialog(
                                                title: const Text('Delete Variant'),
                                                content: Text('Delete variant "${v.sku}"?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dCtx, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  FilledButton(
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: colorScheme.error,
                                                    ),
                                                    onPressed: () => Navigator.pop(dCtx, true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              try {
                                                await widget.productService.deleteVariant(product.id, v.id);
                                                _showSnackbar('Variant deleted');
                                                reloadVariants();
                                              } catch (e) {
                                                _showSnackbar('Cannot delete variant: $e');
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: JoppeSpacing.xs),
                                    if (attrs.isNotEmpty) ...[
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: attrs.entries.map((entry) {
                                          return Chip(
                                            avatar: Icon(
                                              entry.key.toUpperCase() == 'RAM'
                                                  ? Icons.memory
                                                  : entry.key.toUpperCase() == 'GPU'
                                                      ? Icons.videogame_asset_outlined
                                                      : entry.key.toUpperCase() == 'CPU'
                                                          ? Icons.developer_board
                                                          : Icons.settings_suggest_outlined,
                                              size: 14,
                                              color: colorScheme.primary,
                                            ),
                                            label: Text(
                                              '${entry.key}: ${entry.value}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            backgroundColor: colorScheme.surfaceContainerHighest,
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          );
                                        }).toList(),
                                      ),
                                    ] else ...[
                                      Text(
                                        'No structured hardware specs defined.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showVariantFormDialog({
    required ProductItem product,
    ProductVariantSummary? variant,
    VoidCallback? onSaved,
  }) {
    final isEditing = variant != null;
    final skuCtrl = TextEditingController(text: variant?.sku ?? '');
    final nameCtrl = TextEditingController(text: variant?.variantName ?? '');
    final listPriceCtrl = TextEditingController(text: variant != null ? variant.listPrice.toStringAsFixed(0) : '0');
    final salePriceCtrl = TextEditingController(text: variant != null ? variant.salePrice.toStringAsFixed(0) : '0');
    final stockCtrl = TextEditingController(text: variant != null ? variant.quantityOnHand.toString() : '10');
    final weightCtrl = TextEditingController(text: variant != null ? variant.weightGram.toStringAsFixed(0) : '0');
    bool isActive = variant?.isActive ?? true;

    final List<MapEntry<TextEditingController, TextEditingController>> specRows = [];
    if (variant != null && variant.parsedAttributes.isNotEmpty) {
      for (final entry in variant.parsedAttributes.entries) {
        specRows.add(MapEntry(
          TextEditingController(text: entry.key),
          TextEditingController(text: entry.value.toString()),
        ));
      }
    }

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final colorScheme = Theme.of(ctx).colorScheme;

          void addSpecRow(String key, String val) {
            setDialogState(() {
              specRows.add(MapEntry(
                TextEditingController(text: key),
                TextEditingController(text: val),
              ));
            });
          }

          void removeSpecRow(int index) {
            setDialogState(() {
              final row = specRows.removeAt(index);
              row.key.dispose();
              row.value.dispose();
            });
          }

          return AlertDialog(
            title: Text(isEditing ? 'Edit Spec Variant' : 'Add Spec Variant'),
            content: SizedBox(
              width: 580,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: skuCtrl,
                              decoration: const InputDecoration(
                                labelText: 'SKU *',
                                hintText: 'e.g. ROG-G16-32GB-4070',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: JoppeSpacing.sm),
                          Expanded(
                            child: TextFormField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Variant Name *',
                                hintText: 'e.g. 32GB RAM / RTX 4070',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: JoppeSpacing.sm),
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
                        ],
                      ),
                      const SizedBox(height: JoppeSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Quantity On Hand'),
                            ),
                          ),
                          const SizedBox(width: JoppeSpacing.sm),
                          Expanded(
                            child: TextFormField(
                              controller: weightCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Weight (Grams)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: JoppeSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Hardware Specs (RAM, GPU, CPU...)',
                              style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Attribute'),
                            onPressed: () => addSpecRow('', ''),
                          ),
                        ],
                      ),
                      const SizedBox(height: JoppeSpacing.xs),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ActionChip(
                            label: const Text('+ RAM'),
                            onPressed: () => addSpecRow('RAM', '16GB'),
                            visualDensity: VisualDensity.compact,
                          ),
                          ActionChip(
                            label: const Text('+ GPU'),
                            onPressed: () => addSpecRow('GPU', 'RTX 4060'),
                            visualDensity: VisualDensity.compact,
                          ),
                          ActionChip(
                            label: const Text('+ CPU'),
                            onPressed: () => addSpecRow('CPU', 'Core i7'),
                            visualDensity: VisualDensity.compact,
                          ),
                          ActionChip(
                            label: const Text('+ Storage'),
                            onPressed: () => addSpecRow('Storage', '1TB SSD'),
                            visualDensity: VisualDensity.compact,
                          ),
                          ActionChip(
                            label: const Text('+ Color'),
                            onPressed: () => addSpecRow('Color', 'Black'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: JoppeSpacing.sm),
                      if (specRows.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(JoppeSpacing.sm),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'No hardware spec attributes added yet. Click "+ RAM", "+ GPU", or "Add Attribute" above.',
                              style: TextStyle(fontSize: 12, color: colorScheme.outline),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(JoppeSpacing.xs),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: specRows.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 4),
                            itemBuilder: (ctx, idx) {
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: specRows[idx].key,
                                      decoration: const InputDecoration(
                                        hintText: 'Spec (e.g. RAM)',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: JoppeSpacing.xs),
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: specRows[idx].value,
                                      decoration: const InputDecoration(
                                        hintText: 'Value (e.g. 32GB)',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () => removeSpecRow(idx),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: JoppeSpacing.sm),
                      SwitchListTile(
                        title: const Text('Variant Active'),
                        value: isActive,
                        onChanged: (val) => setDialogState(() => isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final Map<String, String> attrMap = {};
                  for (final row in specRows) {
                    final k = row.key.text.trim();
                    final v = row.value.text.trim();
                    if (k.isNotEmpty && v.isNotEmpty) {
                      attrMap[k] = v;
                    }
                  }
                  final String? attributesJson = attrMap.isNotEmpty ? jsonEncode(attrMap) : null;

                  try {
                    if (isEditing) {
                      await widget.productService.updateVariant(
                        product.id,
                        variant.id,
                        sku: skuCtrl.text.trim(),
                        variantName: nameCtrl.text.trim(),
                        attributes: attributesJson,
                        listPrice: double.tryParse(listPriceCtrl.text),
                        salePrice: double.tryParse(salePriceCtrl.text),
                        quantityOnHand: int.tryParse(stockCtrl.text),
                        weightGram: double.tryParse(weightCtrl.text),
                        isActive: isActive,
                      );
                      _showSnackbar('Variant updated successfully');
                    } else {
                      await widget.productService.createVariant(
                        product.id,
                        sku: skuCtrl.text.trim(),
                        variantName: nameCtrl.text.trim(),
                        attributes: attributesJson,
                        listPrice: double.tryParse(listPriceCtrl.text),
                        salePrice: double.tryParse(salePriceCtrl.text),
                        quantityOnHand: int.tryParse(stockCtrl.text),
                        weightGram: double.tryParse(weightCtrl.text),
                        isActive: isActive,
                      );
                      _showSnackbar('Variant created successfully');
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    onSaved?.call();
                    _loadData();
                  } catch (e) {
                    _showSnackbar('Error saving variant: $e');
                  }
                },
                child: Text(isEditing ? 'Save Variant' : 'Create Variant'),
              ),
            ],
          );
        },
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
                                              '/${p.slug} • ${p.variants.length} variant${p.variants.length == 1 ? '' : 's'}${p.variants.isNotEmpty ? ' • ${p.variants.first.sku}' : ''}',
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
                                        icon: const Icon(Icons.tune_outlined),
                                        onPressed: () => _showVariantsDialog(p),
                                        tooltip: 'Manage Variants (${p.variants.length})',
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
