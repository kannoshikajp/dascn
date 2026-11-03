import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import 'warehouse_view.dart';
import 'receipts_view.dart';

export 'warehouse_view.dart';
export 'receipts_view.dart';

class InventoryView extends StatefulWidget {
  final InventoryService inventoryService;
  final ProductManagementService productService;
  final int? fixedTab;

  const InventoryView({
    super.key,
    required this.inventoryService,
    required this.productService,
    this.fixedTab,
  });

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. Receipts tab state
  List<GoodReceiptSummary> _receipts = [];
  bool _isLoadingReceipts = true;
  String? _receiptsError;
  String? _selectedReceiptStatus;
  final _receiptSearchController = TextEditingController();

  // 2. Suppliers tab state
  List<SupplierItem> _suppliers = [];
  bool _isLoadingSuppliers = true;
  String? _suppliersError;
  final _supplierSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.fixedTab ?? 0,
    );
    if (widget.fixedTab == null) {
      _loadAll();
    } else if (widget.fixedTab == 1) {
      _loadReceipts();
    } else if (widget.fixedTab == 2) {
      _loadSuppliers();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receiptSearchController.dispose();
    _supplierSearchController.dispose();
    super.dispose();
  }

  void _loadAll() {
    _loadReceipts();
    _loadSuppliers();
  }

  // ---------------------------------------------------------------------------
  // Data Loaders
  // ---------------------------------------------------------------------------

  Future<void> _loadReceipts() async {
    setState(() {
      _isLoadingReceipts = true;
      _receiptsError = null;
    });

    try {
      final list = await widget.inventoryService.listReceipts(
        status: (_selectedReceiptStatus == null || _selectedReceiptStatus == 'ALL') ? null : _selectedReceiptStatus,
        search: _receiptSearchController.text.trim().isEmpty ? null : _receiptSearchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _receipts = list;
          _isLoadingReceipts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _receiptsError = e.toString().replaceFirst('ApiException: ', '');
          _isLoadingReceipts = false;
        });
      }
    }
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoadingSuppliers = true;
      _suppliersError = null;
    });

    try {
      final list = await widget.inventoryService.listSuppliers(
        search: _supplierSearchController.text.trim().isEmpty ? null : _supplierSearchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _suppliers = list;
          _isLoadingSuppliers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suppliersError = e.toString().replaceFirst('ApiException: ', '');
          _isLoadingSuppliers = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} ₫';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _resolveImageUrl(String url) => ApiClient.resolveUrl(url);

  // ---------------------------------------------------------------------------
  // Tab 1: Receipts View (Inbound)
  // ---------------------------------------------------------------------------

  Widget _buildReceiptsTab(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _receiptSearchController,
                decoration: InputDecoration(
                  hintText: 'Search receipt code...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                ),
                onSubmitted: (_) => _loadReceipts(),
              ),
            ),
            const SizedBox(width: JoppeSpacing.sm),
            FilledButton.icon(
              onPressed: _openCreateReceiptDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Goods Receipt'),
            ),
            const SizedBox(width: JoppeSpacing.sm),
            IconButton.filledTonal(
              onPressed: _loadReceipts,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh receipts',
            ),
          ],
        ),
        const SizedBox(height: JoppeSpacing.md),

        if (_receiptsError != null)
          Text(_receiptsError!, style: TextStyle(color: cs.error)),

        Expanded(
          child: _isLoadingReceipts
              ? const Center(child: CircularProgressIndicator())
              : Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(JoppeShapes.medium),
                    side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Receipt Code', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Supplier', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Staff', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Items', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: _receipts.map((r) {
                                final isCompleted = r.status.toUpperCase() == 'COMPLETED';
                                final statusCol = isCompleted ? Colors.green : Colors.orange;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(r.receiptCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(r.supplierName ?? r.orderCode ?? '-')),
                                    DataCell(Text(r.staffName)),
                                    DataCell(Text('${r.totalItems} pcs')),
                                    DataCell(Text(_formatCurrency(r.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusCol.withAlpha(25),
                                          borderRadius: BorderRadius.circular(JoppeShapes.full),
                                          border: Border.all(color: statusCol.withAlpha(120)),
                                        ),
                                        child: Text(r.status, style: TextStyle(color: statusCol, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    DataCell(Text(_formatDate(r.createdAt), style: const TextStyle(fontSize: 12))),
                                    DataCell(
                                      FilledButton.tonal(
                                        onPressed: () => _openReceiptDetailDialog(r.id),
                                        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                                        child: const Text('View'),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _openCreateReceiptDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CreateReceiptDialog(
        inventoryService: widget.inventoryService,
        productService: widget.productService,
        suppliers: _suppliers,
        onCreated: () {
          _loadReceipts();
        },
        formatCurrency: _formatCurrency,
      ),
    );
  }

  Future<void> _openReceiptDetailDialog(String receiptId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ReceiptDetailDialog(
        receiptId: receiptId,
        inventoryService: widget.inventoryService,
        onReceiptUpdated: () {
          _loadReceipts();
        },
        formatCurrency: _formatCurrency,
        formatDate: _formatDate,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 3: Suppliers Directory
  // ---------------------------------------------------------------------------

  Widget _buildSuppliersTab(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _supplierSearchController,
                decoration: InputDecoration(
                  hintText: 'Search supplier name, contact, phone, email...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                ),
                onSubmitted: (_) => _loadSuppliers(),
              ),
            ),
            const SizedBox(width: JoppeSpacing.sm),
            FilledButton.icon(
              onPressed: () => _openSupplierFormDialog(),
              icon: const Icon(Icons.add_business),
              label: const Text('Add Supplier'),
            ),
            const SizedBox(width: JoppeSpacing.sm),
            IconButton.filledTonal(
              onPressed: _loadSuppliers,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh suppliers',
            ),
          ],
        ),
        const SizedBox(height: JoppeSpacing.md),

        if (_suppliersError != null)
          Text(_suppliersError!, style: TextStyle(color: cs.error)),

        Expanded(
          child: _isLoadingSuppliers
              ? const Center(child: CircularProgressIndicator())
              : Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(JoppeShapes.medium),
                    side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Supplier Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Contact Person', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: _suppliers.map((s) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(s.supplierName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(s.contactPerson ?? '-')),
                                    DataCell(Text(s.phoneNumber ?? '-')),
                                    DataCell(Text(s.email ?? '-')),
                                    DataCell(Text(s.address ?? '-', style: const TextStyle(fontSize: 12))),
                                    DataCell(
                                      Switch(
                                        value: s.isActive,
                                        onChanged: (val) async {
                                          await widget.inventoryService.toggleSupplierStatus(s.id, val);
                                          _loadSuppliers();
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 16),
                                            onPressed: () => _openSupplierFormDialog(supplier: s),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                            onPressed: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (c) => AlertDialog(
                                                  title: const Text('Delete Supplier'),
                                                  content: Text('Delete or deactivate "${s.supplierName}"?'),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                                                  ],
                                                ),
                                              );
                                              if (ok == true) {
                                                await widget.inventoryService.deleteSupplier(s.id);
                                                _loadSuppliers();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _openSupplierFormDialog({SupplierItem? supplier}) async {
    final nameCtrl = TextEditingController(text: supplier?.supplierName ?? '');
    final contactCtrl = TextEditingController(text: supplier?.contactPerson ?? '');
    final phoneCtrl = TextEditingController(text: supplier?.phoneNumber ?? '');
    final emailCtrl = TextEditingController(text: supplier?.email ?? '');
    final addressCtrl = TextEditingController(text: supplier?.address ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(supplier == null ? 'Add New Supplier' : 'Edit Supplier'),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Supplier Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: JoppeSpacing.sm),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(labelText: 'Contact Person', border: OutlineInputBorder()),
              ),
              const SizedBox(height: JoppeSpacing.sm),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: JoppeSpacing.sm),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: JoppeSpacing.sm),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              if (supplier == null) {
                await widget.inventoryService.createSupplier(
                  supplierName: nameCtrl.text.trim(),
                  contactPerson: contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                );
              } else {
                await widget.inventoryService.updateSupplier(
                  id: supplier.id,
                  supplierName: nameCtrl.text.trim(),
                  contactPerson: contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                  address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true) {
      _loadSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (widget.fixedTab != null) {
      if (widget.fixedTab == 0) {
        return WarehouseView(inventoryService: widget.inventoryService);
      }
      if (widget.fixedTab == 1) {
        return ReceiptsView(
          inventoryService: widget.inventoryService,
          productService: widget.productService,
        );
      }

      String title = 'Suppliers Directory';
      Widget content = _buildSuppliersTab(cs);
      VoidCallback onRefresh = _loadSuppliers;

      return Padding(
        padding: const EdgeInsets.all(JoppeSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: JoppeSpacing.md),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Inventory & Supply Chain', style: Theme.of(context).textTheme.headlineMedium),
              IconButton(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh all tabs',
              ),
            ],
          ),
          const SizedBox(height: JoppeSpacing.sm),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.warehouse_outlined), text: 'Warehouse'),
              Tab(icon: Icon(Icons.input), text: 'Goods Receipts (Inbound)'),
              Tab(icon: Icon(Icons.business), text: 'Suppliers Directory'),
            ],
          ),
          const SizedBox(height: JoppeSpacing.md),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                WarehouseView(inventoryService: widget.inventoryService),
                ReceiptsView(
                  inventoryService: widget.inventoryService,
                  productService: widget.productService,
                ),
                _buildSuppliersTab(Theme.of(context).colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Inbound Receipt Creation Modal
// -----------------------------------------------------------------------------

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

class _CreateReceiptDialog extends StatefulWidget {
  final InventoryService inventoryService;
  final ProductManagementService productService;
  final List<SupplierItem> suppliers;
  final VoidCallback onCreated;
  final String Function(double) formatCurrency;

  const _CreateReceiptDialog({
    required this.inventoryService,
    required this.productService,
    required this.suppliers,
    required this.onCreated,
    required this.formatCurrency,
  });

  @override
  State<_CreateReceiptDialog> createState() => _CreateReceiptDialogState();
}

class _CreateReceiptDialogState extends State<_CreateReceiptDialog> {
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
          const SnackBar(content: Text('Goods Receipt created and stock updated successfully!')),
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
                        Text('Inbound Goods Receipt / Import Batch', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(height: 20),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: JoppeSpacing.sm),
                        child: Text(_error!, style: TextStyle(color: cs.error)),
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
                            const Text('Add stock now'),
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
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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

// -----------------------------------------------------------------------------
// Receipt Detail Inspection Dialog
// -----------------------------------------------------------------------------

class _ReceiptDetailDialog extends StatefulWidget {
  final String receiptId;
  final InventoryService inventoryService;
  final VoidCallback onReceiptUpdated;
  final String Function(double) formatCurrency;
  final String Function(DateTime?) formatDate;

  const _ReceiptDetailDialog({
    required this.receiptId,
    required this.inventoryService,
    required this.onReceiptUpdated,
    required this.formatCurrency,
    required this.formatDate,
  });

  @override
  State<_ReceiptDetailDialog> createState() => _ReceiptDetailDialogState();
}

class _ReceiptDetailDialogState extends State<_ReceiptDetailDialog> {
  GoodReceiptDetail? _receipt;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final detail = await widget.inventoryService.getReceiptDetail(widget.receiptId);
      if (mounted) {
        setState(() {
          _receipt = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _complete() async {
    try {
      await widget.inventoryService.completeReceipt(widget.receiptId);
      widget.onReceiptUpdated();
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(JoppeShapes.large)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.lg),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_error != null)
                  ? Center(child: Text(_error!, style: TextStyle(color: cs.error)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_receipt!.receiptCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Text('Supplier: ${_receipt!.supplierName} • Created on ${widget.formatDate(_receipt!.createdAt)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                              ],
                            ),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                        const Divider(height: 20),

                        Row(
                          children: [
                            Text('Status: ${_receipt!.status}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (_receipt!.status == 'DRAFT')
                              FilledButton.icon(
                                onPressed: _complete,
                                icon: const Icon(Icons.check),
                                label: const Text('Complete & Add Stock'),
                              ),
                          ],
                        ),
                        const SizedBox(height: JoppeSpacing.md),

                        Expanded(
                          child: ListView.separated(
                            itemCount: _receipt!.items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final item = _receipt!.items[idx];
                              return ListTile(
                                title: Text('${item.productName} • ${item.variantName} (SKU: ${item.sku})'),
                                subtitle: Text('Import price: ${widget.formatCurrency(item.importPrice)} x ${item.quantity} pcs'),
                                trailing: Text(widget.formatCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Imported Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(widget.formatCurrency(_receipt!.totalAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cs.primary)),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
