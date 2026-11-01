import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../localization/dashboard_localizations.dart';
import 'receipts/atoms/receipt_kpi_card.dart';
import 'receipts/atoms/receipt_status_badge.dart';
import 'receipts/atoms/receipt_type_badge.dart';
import 'receipts/molecules/create_receipt_dialog.dart';
import 'receipts/molecules/receipt_detail_dialog.dart';
import 'receipts/molecules/receipt_filter_bar.dart';
import 'receipts/organisms/receipt_kpi_row.dart';
import 'receipts/organisms/receipt_table_view.dart';

export 'receipts/atoms/receipt_kpi_card.dart';
export 'receipts/atoms/receipt_status_badge.dart';
export 'receipts/atoms/receipt_type_badge.dart';
export 'receipts/molecules/create_receipt_dialog.dart';
export 'receipts/molecules/receipt_detail_dialog.dart';
export 'receipts/molecules/receipt_filter_bar.dart';
export 'receipts/organisms/receipt_kpi_row.dart';
export 'receipts/organisms/receipt_table_view.dart';

/// Screen: Stock Movements & Goods Receipts (Inbound & Outbound) view
/// following Atomic Design principles.
class ReceiptsView extends StatefulWidget {
  final InventoryService inventoryService;
  final ProductManagementService productService;

  const ReceiptsView({
    super.key,
    required this.inventoryService,
    required this.productService,
  });

  @override
  State<ReceiptsView> createState() => _ReceiptsViewState();
}

class _ReceiptsViewState extends State<ReceiptsView> {
  final TextEditingController _searchController = TextEditingController();
  List<GoodReceiptSummary> _allReceipts = [];
  List<SupplierItem> _suppliers = [];
  bool _isLoading = true;
  String? _error;

  ReceiptTypeFilter _selectedTypeFilter = ReceiptTypeFilter.all;
  ReceiptStatusFilter _selectedStatusFilter = ReceiptStatusFilter.all;

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
        widget.inventoryService.listReceipts(),
        widget.inventoryService.listSuppliers(),
      ]);

      if (mounted) {
        setState(() {
          _allReceipts = results[0] as List<GoodReceiptSummary>;
          _suppliers = results[1] as List<SupplierItem>;
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

  List<GoodReceiptSummary> get _filteredReceipts {
    final query = _searchController.text.trim().toLowerCase();

    return _allReceipts.where((r) {
      // Type filter
      if (_selectedTypeFilter == ReceiptTypeFilter.inbound && !r.isInbound) {
        return false;
      }
      if (_selectedTypeFilter == ReceiptTypeFilter.outbound && !r.isOutbound) {
        return false;
      }

      // Status filter
      if (_selectedStatusFilter == ReceiptStatusFilter.completed && !r.isCompleted) {
        return false;
      }
      if (_selectedStatusFilter == ReceiptStatusFilter.draft && r.isCompleted) {
        return false;
      }

      // Query filter
      if (query.isNotEmpty) {
        final matchCode = r.receiptCode.toLowerCase().contains(query);
        final matchSup = r.supplierName != null && r.supplierName!.toLowerCase().contains(query);
        final matchOrder = r.orderCode != null && r.orderCode!.toLowerCase().contains(query);
        final matchStaff = r.staffName.toLowerCase().contains(query);
        final matchNote = r.note != null && r.note!.toLowerCase().contains(query);
        if (!matchCode && !matchSup && !matchOrder && !matchStaff && !matchNote) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedTypeFilter = ReceiptTypeFilter.all;
      _selectedStatusFilter = ReceiptStatusFilter.all;
    });
    _loadData();
  }

  String _formatCurrency(double amount) {
    final isNeg = amount < 0;
    final abs = amount.abs().toStringAsFixed(0);
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = abs.replaceAllMapped(reg, (m) => '${m[1]},');
    return '${isNeg ? '-' : ''}$formatted ₫';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _openCreateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CreateReceiptDialog(
        inventoryService: widget.inventoryService,
        productService: widget.productService,
        suppliers: _suppliers,
        onCreated: _loadData,
        formatCurrency: _formatCurrency,
      ),
    );
  }

  void _openDetailDialog(String receiptId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReceiptDetailDialog(
        receiptId: receiptId,
        inventoryService: widget.inventoryService,
        onReceiptUpdated: _loadData,
        formatCurrency: _formatCurrency,
        formatDate: _formatDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final inboundCount = _allReceipts.where((r) => r.isInbound).length;
    final outboundCount = _allReceipts.where((r) => r.isOutbound).length;

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. KPI Overview Row
          ReceiptKpiRow(
            receipts: _allReceipts,
            formatCurrency: _formatCurrency,
          ),
          const SizedBox(height: JoppeSpacing.md),

          // 2. Filter Bar Molecule
          ReceiptFilterBar(
            searchController: _searchController,
            selectedTypeFilter: _selectedTypeFilter,
            selectedStatusFilter: _selectedStatusFilter,
            totalCount: _allReceipts.length,
            inboundCount: inboundCount,
            outboundCount: outboundCount,
            onSelectType: (val) => setState(() => _selectedTypeFilter = val),
            onSelectStatus: (val) => setState(() => _selectedStatusFilter = val),
            onSearchChanged: () => setState(() {}),
            onReset: _resetFilters,
            onNewReceipt: _openCreateDialog,
          ),
          const SizedBox(height: JoppeSpacing.md),

          // 3. Tabular Content Display
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
                    : ReceiptTableView(
                        receipts: _filteredReceipts,
                        onOpenDetail: _openDetailDialog,
                        formatCurrency: _formatCurrency,
                        formatDate: _formatDate,
                      ),
          ),
        ],
      ),
    );
  }
}
