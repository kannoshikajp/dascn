import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/receipt_status_badge.dart';
import '../atoms/receipt_type_badge.dart';

/// Molecule: Detail inspection dialog for stock receipt movements (Inbound & Outbound).
class ReceiptDetailDialog extends StatefulWidget {
  final String receiptId;
  final InventoryService inventoryService;
  final VoidCallback onReceiptUpdated;
  final String Function(double) formatCurrency;
  final String Function(DateTime?) formatDate;

  const ReceiptDetailDialog({
    super.key,
    required this.receiptId,
    required this.inventoryService,
    required this.onReceiptUpdated,
    required this.formatCurrency,
    required this.formatDate,
  });

  @override
  State<ReceiptDetailDialog> createState() => _ReceiptDetailDialogState();
}

class _ReceiptDetailDialogState extends State<ReceiptDetailDialog> {
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
          _error = e.toString().replaceFirst('ApiException: ', '');
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
    final l10n = context.l10n;

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
                        // Top title row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: JoppeSpacing.sm,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        _receipt!.receiptCode,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      ReceiptTypeBadge(receiptType: _receipt!.receiptType),
                                      ReceiptStatusBadge(status: _receipt!.status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _receipt!.isOutbound
                                        ? 'Order: ${_receipt!.orderCode ?? _receipt!.orderId ?? 'Online/Showroom'} • Created on ${widget.formatDate(_receipt!.createdAt)}'
                                        : 'Supplier: ${_receipt!.supplierName ?? 'Direct Import'} • Created on ${widget.formatDate(_receipt!.createdAt)}',
                                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                                  ),
                                  if (_receipt!.note != null && _receipt!.note!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      _receipt!.note!,
                                      style: TextStyle(color: cs.primary, fontSize: 11, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                        const Divider(height: 20),

                        // Action bar (Complete DRAFT if inbound)
                        if (_receipt!.isInbound && _receipt!.status.toUpperCase() == 'DRAFT') ...[
                          Row(
                            children: [
                              Text(
                                '${l10n.movementStatus}: ${_receipt!.status}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: _complete,
                                icon: const Icon(Icons.check, size: 16),
                                label: Text(l10n.completeAndAddStock),
                              ),
                            ],
                          ),
                          const SizedBox(height: JoppeSpacing.sm),
                        ],

                        // Items list
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                              borderRadius: BorderRadius.circular(JoppeShapes.small),
                            ),
                            child: ListView.separated(
                              itemCount: _receipt!.items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final item = _receipt!.items[idx];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    '${item.productName} • ${item.variantName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    'SKU: ${item.sku} • Qty: ${item.quantity} x ${widget.formatCurrency(item.importPrice)}',
                                  ),
                                  trailing: Text(
                                    widget.formatCurrency(item.subtotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: JoppeSpacing.md),

                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${l10n.totalAmount}:',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              widget.formatCurrency(_receipt!.totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: cs.primary,
                              ),
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
