import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

class _ReceiptDraftItem {
  final String variantId;
  final String productName;
  final String variantName;
  final String sku;
  int quantity;
  double importPrice;

  _ReceiptDraftItem({
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.sku,
    required this.quantity,
    required this.importPrice,
  });

  double get subtotal => quantity * importPrice;
}

/// Molecule: Modal dialog for creating inbound stock receipts and importing batches.
class CreateReceiptDialog extends StatefulWidget {
  final InventoryService inventoryService;
  final ProductManagementService productService;
  final List<SupplierItem> suppliers;
  final VoidCallback onCreated;
  final String Function(double) formatCurrency;

  const CreateReceiptDialog({
    super.key,
    required this.inventoryService,
    required this.productService,
    required this.suppliers,
    required this.onCreated,
    required this.formatCurrency,
  });

  @override
  State<CreateReceiptDialog> createState() => _CreateReceiptDialogState();
}

class _CreateReceiptDialogState extends State<CreateReceiptDialog> {
  SupplierItem? _selectedSupplier;
  final _receiptCodeCtrl = TextEditingController();
  bool _completeImmediately = true;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  List<ProductItem> _products = [];
  ProductItem? _selectedProduct;
  ProductVariantSummary? _selectedVariant;
  int _itemQuantity = 10;
  final _importPriceCtrl = TextEditingController(text: '1000000');
  final List<_ReceiptDraftItem> _items = [];

  @override
  void initState() {
    super.initState();
    if (widget.suppliers.isNotEmpty) {
      _selectedSupplier = widget.suppliers.first;
    }
    _loadProducts();
  }

  @override
  void dispose() {
    _receiptCodeCtrl.dispose();
    _importPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final list = await widget.productService.listProducts();
      if (mounted) {
        setState(() {
          _products = list;
          if (_products.isNotEmpty) {
            _selectedProduct = _products.first;
            if (_selectedProduct!.variants.isNotEmpty) {
              _selectedVariant = _selectedProduct!.variants.first;
            }
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addItem() {
    if (_selectedProduct == null || _selectedVariant == null) return;
    final price = double.tryParse(_importPriceCtrl.text.trim()) ?? 0.0;
    if (price <= 0 || _itemQuantity <= 0) return;

    setState(() {
      final existingIdx = _items.indexWhere((i) => i.variantId == _selectedVariant!.id);
      if (existingIdx >= 0) {
        _items[existingIdx].quantity += _itemQuantity;
        _items[existingIdx].importPrice = price;
      } else {
        _items.add(_ReceiptDraftItem(
          variantId: _selectedVariant!.id,
          productName: _selectedProduct!.productName,
          variantName: _selectedVariant!.variantName,
          sku: _selectedVariant!.sku,
          quantity: _itemQuantity,
          importPrice: price,
        ));
      }
    });
  }

  double get _totalReceiptAmount => _items.fold(0.0, (sum, i) => sum + i.subtotal);

  Future<void> _submit() async {
    if (_selectedSupplier == null) {
      setState(() => _error = 'Please select a supplier');
      return;
    }
    if (_items.isEmpty) {
      setState(() => _error = 'Please add at least one line item to import');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.inventoryService.createReceipt(
        supplierId: _selectedSupplier!.id,
        receiptCode: _receiptCodeCtrl.text.trim().isEmpty ? null : _receiptCodeCtrl.text.trim(),
        completeImmediately: _completeImmediately,
        items: _items.map((i) => {
          'variantId': i.variantId,
          'quantity': i.quantity,
          'importPrice': i.importPrice,
        }).toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inbound goods receipt created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = e.toString().replaceFirst('ApiException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(JoppeShapes.large)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.lg),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.input_rounded, color: Colors.teal.shade700, size: 24),
                            const SizedBox(width: JoppeSpacing.sm),
                            Text(
                              l10n.newInboundReceipt,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(height: 20),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: JoppeSpacing.sm),
                        child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
                      ),

                    // Top Supplier & Code Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<SupplierItem>(
                            value: _selectedSupplier,
                            decoration: const InputDecoration(labelText: 'Supplier *', border: OutlineInputBorder(), isDense: true),
                            items: widget.suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.supplierName))).toList(),
                            onChanged: (v) => setState(() => _selectedSupplier = v),
                          ),
                        ),
                        const SizedBox(width: JoppeSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _receiptCodeCtrl,
                            decoration: const InputDecoration(labelText: 'Receipt Code (Optional)', hintText: 'Auto-generated', border: OutlineInputBorder(), isDense: true),
                          ),
                        ),
                        const SizedBox(width: JoppeSpacing.sm),
                        Row(
                          children: [
                            Checkbox(
                              value: _completeImmediately,
                              onChanged: (v) => setState(() => _completeImmediately = v ?? true),
                            ),
                            const Text('Add stock now', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: JoppeSpacing.md),

                    // Add items bar
                    Container(
                      padding: const EdgeInsets.all(JoppeSpacing.md),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(JoppeShapes.small),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<ProductItem>(
                              value: _selectedProduct,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Product', border: OutlineInputBorder(), isDense: true),
                              items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p.productName, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (p) => setState(() {
                                _selectedProduct = p;
                                _selectedVariant = (p != null && p.variants.isNotEmpty) ? p.variants.first : null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<ProductVariantSummary>(
                              value: _selectedVariant,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Spec Variant', border: OutlineInputBorder(), isDense: true),
                              items: (_selectedProduct?.variants ?? []).map((v) => DropdownMenuItem(value: v, child: Text('${v.variantName} (${v.sku})', overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _selectedVariant = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder(), isDense: true),
                              controller: TextEditingController(text: '$_itemQuantity'),
                              onChanged: (v) => _itemQuantity = int.tryParse(v) ?? 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _importPriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Import Cost (₫)', border: OutlineInputBorder(), isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: JoppeSpacing.sm),

                    // Draft items list
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                          borderRadius: BorderRadius.circular(JoppeShapes.small),
                        ),
                        child: _items.isEmpty
                            ? const Center(child: Text('No line items added yet'))
                            : ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final item = _items[idx];
                                  return ListTile(
                                    dense: true,
                                    title: Text('${item.productName} • ${item.variantName} (SKU: ${item.sku})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    subtitle: Text('Qty: ${item.quantity} x ${widget.formatCurrency(item.importPrice)}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(widget.formatCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                          onPressed: () => setState(() => _items.removeAt(idx)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: JoppeSpacing.sm),

                    // Footer Total & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Batch Cost: ${widget.formatCurrency(_totalReceiptAmount)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.primary)),
                        Row(
                          children: [
                            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: Text(_isSubmitting ? 'Importing...' : 'Complete Import'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
