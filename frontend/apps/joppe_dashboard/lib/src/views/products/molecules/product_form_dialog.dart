import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../../../widgets/image_upload_field.dart';
import '../../../widgets/markdown_editor_field.dart';

/// Molecule: Modal dialog for creating or editing a product.
class ProductFormDialog extends StatefulWidget {
  final ProductItem? product;
  final List<ProductItem> allProducts;
  final List<CategoryItem> categories;
  final ProductManagementService productService;
  final MediaUploadService? mediaUploadService;
  final VoidCallback onSaved;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.allProducts,
    required this.categories,
    required this.productService,
    this.mediaUploadService,
    required this.onSaved,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _slugCtrl;
  late final TextEditingController _listPriceCtrl;
  late final TextEditingController _salePriceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _thumbCtrl;
  late final TextEditingController _descCtrl;

  String? _selectedParentSku;
  late Set<int> _selectedCategoryIds;
  int? _primaryCategoryId;
  late bool _isActive;
  bool _isSaving = false;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.productName ?? '');
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _slugCtrl = TextEditingController(text: p?.slug ?? '');
    _selectedParentSku = p?.parentSku;

    final defaultVariant = (p != null && p.variants.isNotEmpty) ? p.variants.first : null;
    final listPriceVal = (defaultVariant != null && defaultVariant.listPrice > 0)
        ? defaultVariant.listPrice
        : (p != null && p.maxPrice > 0 ? p.maxPrice : (p != null ? p.effectivePrice : 0.0));
    final salePriceVal = (defaultVariant != null && defaultVariant.salePrice > 0)
        ? defaultVariant.salePrice
        : listPriceVal;

    _listPriceCtrl = TextEditingController(text: listPriceVal > 0 ? listPriceVal.toStringAsFixed(0) : '0');
    _salePriceCtrl = TextEditingController(text: salePriceVal > 0 ? salePriceVal.toStringAsFixed(0) : '0');
    _stockCtrl = TextEditingController(
        text: defaultVariant != null ? defaultVariant.quantityOnHand.toString() : (p?.totalStock.toString() ?? '10'));
    _thumbCtrl = TextEditingController(text: p?.thumbnailUrl ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');

    _selectedCategoryIds = p != null ? p.categories.map((c) => c.id).toSet() : <int>{};
    _primaryCategoryId = p?.categories.where((c) => c.isPrimary).map((c) => c.id).firstOrNull ??
        (_selectedCategoryIds.isNotEmpty ? _selectedCategoryIds.first : null);
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _slugCtrl.dispose();
    _listPriceCtrl.dispose();
    _salePriceCtrl.dispose();
    _stockCtrl.dispose();
    _thumbCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _slugify(String input) {
    return input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '-');
  }

  double? _parsePrice(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    setState(() => _isSaving = true);

    try {
      final listPrice = _parsePrice(_listPriceCtrl.text) ?? 0.0;
      final rawSalePrice = _parsePrice(_salePriceCtrl.text);
      final salePrice = (rawSalePrice != null && rawSalePrice > 0) ? rawSalePrice : listPrice;
      final stock = int.tryParse(_stockCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      if (isEditing) {
        await widget.productService.updateProduct(
          id: widget.product!.id,
          productName: _nameCtrl.text.trim(),
          sku: _skuCtrl.text.trim(),
          parentSku: _selectedParentSku,
          slug: widget.product!.slug,
          categoryIds: _selectedCategoryIds.toList(),
          primaryCategoryId: _primaryCategoryId,
          isActive: _isActive,
          listPrice: listPrice,
          salePrice: salePrice,
          stockQuantity: stock,
          thumbnailUrl: _thumbCtrl.text.trim().isEmpty ? null : _thumbCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.productUpdatedSuccess)));
          widget.onSaved();
        }
      } else {
        await widget.productService.createProduct(
          productName: _nameCtrl.text.trim(),
          sku: _skuCtrl.text.trim(),
          parentSku: _selectedParentSku,
          slug: _slugCtrl.text.trim().isEmpty ? null : _slugCtrl.text.trim(),
          categoryIds: _selectedCategoryIds.toList(),
          primaryCategoryId: _primaryCategoryId,
          isActive: _isActive,
          thumbnailUrl: _thumbCtrl.text.trim().isEmpty ? null : _thumbCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          listPrice: listPrice,
          salePrice: salePrice,
          stockQuantity: stock,
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.productCreatedSuccess)));
          widget.onSaved();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(isEditing ? l10n.editProductTitle(widget.product!.productName) : l10n.addNewProductTitle),
      content: SizedBox(
        width: 750,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Core Info
                Text(
                  l10n.productCoreInfo,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: JoppeSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.productNameLabel,
                          hintText: 'e.g. ASUS ROG Strix GeForce RTX 4080 Super',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? l10n.productNameRequired : null,
                      ),
                    ),
                    const SizedBox(width: JoppeSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _skuCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.skuLabel,
                          hintText: 'e.g. ROG-RTX4080S-16G',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? l10n.skuRequired : null,
                        onChanged: (v) {
                          if (!isEditing && (_slugCtrl.text.isEmpty || _slugCtrl.text == _slugify(_skuCtrl.text))) {
                            setState(() {
                              _slugCtrl.text = _slugify(v);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: JoppeSpacing.sm),

                // Variant Group Relationship
                DropdownButtonFormField<String?>(
                  value: _selectedParentSku,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.isVariantOfLabel,
                    helperText: l10n.isVariantOfHelper,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        l10n.standaloneProductOption,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    ...widget.allProducts
                        .where((p) => !isEditing || p.sku != widget.product!.sku)
                        .map((p) => DropdownMenuItem(
                              value: p.sku,
                              child: Text(
                                '${p.productName} (${p.sku})',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            )),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedParentSku = val);
                  },
                ),
                const SizedBox(height: JoppeSpacing.sm),

                // Slug Input
                TextFormField(
                  controller: _slugCtrl,
                  readOnly: isEditing,
                  decoration: InputDecoration(
                    labelText: isEditing ? l10n.baseUrlSlugLockedLabel : l10n.baseUrlSlugLabel,
                    prefixIcon: isEditing ? const Icon(Icons.lock_outline, size: 18) : null,
                    helperText: isEditing ? l10n.slugLockedHelper : l10n.slugAutoHelper,
                    filled: isEditing,
                  ),
                  validator: (v) => isEditing && (v == null || v.trim().isEmpty) ? l10n.productNameRequired : null,
                ),
                const SizedBox(height: JoppeSpacing.md),

                // Categories Selector
                Text(
                  l10n.categoriesLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: JoppeSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(JoppeSpacing.sm),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: widget.categories.isEmpty
                      ? Center(child: Text(l10n.noCategoriesAvailable))
                      : ListView(
                          shrinkWrap: true,
                          children: widget.categories.map((cat) {
                            final isSelected = _selectedCategoryIds.contains(cat.id);
                            final isPrimary = _primaryCategoryId == cat.id;

                            return CheckboxListTile(
                              dense: true,
                              title: Row(
                                children: [
                                  Text(cat.parentName != null ? '${cat.parentName} > ${cat.categoryName}' : cat.categoryName),
                                  if (isSelected) ...[
                                    const SizedBox(width: JoppeSpacing.xs),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _primaryCategoryId = cat.id);
                                      },
                                      child: Chip(
                                        label: Text(
                                          isPrimary ? l10n.primaryBadge : l10n.makePrimaryBtn,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isPrimary ? cs.onPrimary : null,
                                          ),
                                        ),
                                        backgroundColor: isPrimary ? cs.primary : null,
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedCategoryIds.add(cat.id);
                                    _primaryCategoryId ??= cat.id;
                                  } else {
                                    _selectedCategoryIds.remove(cat.id);
                                    if (_primaryCategoryId == cat.id) {
                                      _primaryCategoryId =
                                          _selectedCategoryIds.isNotEmpty ? _selectedCategoryIds.first : null;
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: JoppeSpacing.md),

                // Price & Inventory
                Text(
                  l10n.priceAndInventorySection,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: JoppeSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _listPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l10n.listPriceLabel),
                      ),
                    ),
                    const SizedBox(width: JoppeSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _salePriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l10n.salePriceLabel),
                      ),
                    ),
                    const SizedBox(width: JoppeSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: isEditing ? l10n.stockQuantityLabel : l10n.initialStockLabel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: JoppeSpacing.sm),
                ImageUploadField(
                  controller: _thumbCtrl,
                  mediaUploadService: widget.mediaUploadService,
                  label: l10n.thumbnailOptionalLabel,
                  folder: 'products',
                ),
                const SizedBox(height: JoppeSpacing.sm),
                MarkdownEditorField(
                  controller: _descCtrl,
                  mediaUploadService: widget.mediaUploadService,
                  label: l10n.markdownDescOptionalLabel,
                ),
                const SizedBox(height: JoppeSpacing.sm),
                SwitchListTile(
                  title: Text(l10n.productActiveSwitch),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEditing ? l10n.saveChanges : l10n.createProductSubmit),
        ),
      ],
    );
  }
}
