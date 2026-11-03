import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/order_status_badge.dart';

/// Molecule: Order details dialog with status mutations, line items, and pricing breakdown.
class OrderDetailDialog extends StatefulWidget {
  final String orderId;
  final OrderService orderService;
  final VoidCallback onOrderUpdated;
  final String Function(double) formatCurrency;
  final String Function(DateTime?) formatDate;

  const OrderDetailDialog({
    super.key,
    required this.orderId,
    required this.orderService,
    required this.onOrderUpdated,
    required this.formatCurrency,
    required this.formatDate,
  });

  @override
  State<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {
  OrderDetailModel? _order;
  bool _isLoading = true;
  String? _error;
  bool _isUpdating = false;

  List<String> _getAllowedNextStatuses(String current) {
    switch (current.toUpperCase()) {
      case 'ACCEPTED':
      case 'PENDING':
      case 'CONFIRMED':
        return [current, 'PACKAGING', 'REFUND'];
      case 'PACKAGING':
      case 'PACKING':
        return [current, 'DELIVERY', 'REFUND'];
      case 'DELIVERY':
        return [current, 'SHIPPED', 'REFUND'];
      case 'SHIPPED':
      case 'DELIVERED':
      case 'SHOWROOM_BUY':
        return [current, 'REFUND'];
      case 'REFUND':
      case 'CANCELLED':
        return [current];
      default:
        return [current, 'ACCEPTED', 'PACKAGING', 'DELIVERY', 'SHIPPED', 'REFUND'];
    }
  }

  List<String> _getAllowedNextPaymentStatuses(String current) {
    switch (current.toUpperCase()) {
      case 'PAID':
        return [current, 'REFUND'];
      case 'UNPAID':
        return [current, 'PAID', 'REFUND'];
      case 'REFUND':
      case 'REFUNDED':
        return [current];
      default:
        return [current, 'PAID', 'REFUND'];
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await widget.orderService.getAdminOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = detail;
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

  Future<void> _updateStatus(String newStatus) async {
    if (_order == null || _order!.orderStatus == newStatus) return;

    final l10n = context.l10n;
    setState(() => _isUpdating = true);
    try {
      final updated = await widget.orderService.updateOrderStatus(widget.orderId, newStatus);
      if (mounted) {
        setState(() {
          _order = updated;
          _isUpdating = false;
        });
        widget.onOrderUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.orderStatusUpdated(l10n.orderStatusLabel(newStatus)))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdateStatus(e))),
        );
      }
    }
  }

  Future<void> _updatePaymentStatus(String newPaymentStatus) async {
    if (_order == null || _order!.paymentStatus == newPaymentStatus) return;

    final l10n = context.l10n;
    setState(() => _isUpdating = true);
    try {
      final updated = await widget.orderService.updatePaymentStatus(widget.orderId, newPaymentStatus);
      if (mounted) {
        setState(() {
          _order = updated;
          _isUpdating = false;
        });
        widget.onOrderUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentStatusUpdated(l10n.paymentStatusLabel(newPaymentStatus)))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdatePayment(e))),
        );
      }
    }
  }

  String _resolveImageUrl(String url) => ApiClient.resolveUrl(url);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(JoppeShapes.large)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 750),
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.lg),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_error != null)
                  ? Center(child: Text(_error!, style: TextStyle(color: cs.error)))
                  : _buildContent(cs),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs) {
    final l10n = context.l10n;
    final order = _order!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.orderCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(width: JoppeSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (order.orderChannel == 'SHOWROOM')
                            ? Colors.teal.withAlpha(30)
                            : cs.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(JoppeShapes.small),
                        border: Border.all(
                          color: (order.orderChannel == 'SHOWROOM') ? Colors.teal : cs.primary,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        order.orderChannel == 'SHOWROOM' ? 'SHOWROOM' : 'ONLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: (order.orderChannel == 'SHOWROOM') ? Colors.teal : cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: JoppeSpacing.sm),
                    if (_isUpdating)
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                Text(
                  l10n.placedOnDate(widget.formatDate(order.createdAt)),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const Divider(height: 24),

        // Status Controls Row
        Row(
          children: [
            Expanded(
              child: Card(
                color: cs.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Text('${l10n.orderStatus}: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: order.orderStatus,
                          underline: const SizedBox.shrink(),
                          isDense: true,
                          isExpanded: true,
                          items: _getAllowedNextStatuses(order.orderStatus).map((st) {
                            final col = OrderStatusBadge.getStatusColor(st, cs);
                            return DropdownMenuItem(
                              value: st,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.orderStatusLabel(st),
                                      style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _isUpdating ? null : (v) => v != null ? _updateStatus(v) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: JoppeSpacing.sm),
            Expanded(
              child: Card(
                color: cs.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Text('${l10n.paymentStatus}: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: order.paymentStatus,
                          underline: const SizedBox.shrink(),
                          isDense: true,
                          isExpanded: true,
                          items: _getAllowedNextPaymentStatuses(order.paymentStatus).map((pst) {
                            final col = OrderStatusBadge.getPaymentColor(pst, cs);
                            return DropdownMenuItem(
                              value: pst,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      l10n.paymentStatusLabel(pst),
                                      style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _isUpdating ? null : (v) => v != null ? _updatePaymentStatus(v) : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: JoppeSpacing.sm),

        if (order.manualPaymentRef != null && order.manualPaymentRef!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(JoppeShapes.medium),
              border: Border.all(color: Colors.blue.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xác nhận thủ công: ${order.manualPaymentRef}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
                      ),
                      if (order.paymentConfirmNote != null && order.paymentConfirmNote!.isNotEmpty)
                        Text(
                          'Ghi chú: ${order.paymentConfirmNote}',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: JoppeSpacing.sm),
        ],

        // Recipient details box
        Container(
          padding: const EdgeInsets.all(JoppeSpacing.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(JoppeShapes.medium),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.shippingDetails, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${order.recipientName} • ${order.recipientPhone}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(order.shippingAddress, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              if (order.customerNote != null && order.customerNote!.isNotEmpty) ...[
                const SizedBox(width: JoppeSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.customerNote, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(order.customerNote!, style: TextStyle(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: JoppeSpacing.md),

        // Items list
        Text(l10n.lineItems, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant.withAlpha(60)),
              borderRadius: BorderRadius.circular(JoppeShapes.small),
            ),
            child: ListView.separated(
              itemCount: order.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final item = order.items[idx];
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(JoppeShapes.small),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            _resolveImageUrl(item.thumbnailUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 20),
                          )
                        : const Icon(Icons.image, size: 20),
                  ),
                  title: Text(item.productNameSnapshot, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.variantNameSnapshot} (SKU: ${item.skuSnapshot}) • ${l10n.warrantyMonthsSnapshot(item.warrantyMonthsSnapshot)}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                      if (item.serialNumbers.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.qr_code_2, size: 13, color: Colors.blue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'SN: ${item.serialNumbers.join(", ")}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(widget.formatCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${widget.formatCurrency(item.unitPrice)} x ${item.quantity}',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: JoppeSpacing.sm),

        // Pricing summary footer
        Container(
          padding: const EdgeInsets.all(JoppeSpacing.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(JoppeShapes.medium),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.subtotalLabel),
                  Text(widget.formatCurrency(order.subtotalAmount)),
                ],
              ),
              if (order.shippingFee > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.shippingFeeLabel),
                    Text('+ ${widget.formatCurrency(order.shippingFee)}'),
                  ],
                ),
              if (order.discountAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.discountLabel),
                    Text('- ${widget.formatCurrency(order.discountAmount)}', style: const TextStyle(color: Colors.green)),
                  ],
                ),
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.finalTotalLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    widget.formatCurrency(order.finalAmount),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: cs.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
