import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/order_status_badge.dart';

/// Organism: Data table displaying the list of orders with atomic badges,
/// bidirectional scrollbars (vertical for overflow height and horizontal for columns).
class OrdersTable extends StatefulWidget {
  final List<OrderSummaryModel> orders;
  final String Function(double) formatCurrency;
  final String Function(DateTime?) formatDate;
  final ValueChanged<String> onOpenDetail;

  const OrdersTable({
    super.key,
    required this.orders,
    required this.formatCurrency,
    required this.formatDate,
    required this.onOpenDetail,
  });

  @override
  State<OrdersTable> createState() => _OrdersTableState();
}

class _OrdersTableState extends State<OrdersTable> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (widget.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: JoppeSpacing.sm),
              Text(l10n.noOrdersMatching, style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _verticalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalController,
            scrollDirection: Axis.vertical,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
                    columns: [
                      DataColumn(label: Text(l10n.orderCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.customer, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.itemsCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.totalAmount, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.orderStatus, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.paymentStatus, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.placedAtCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text(l10n.actionCol, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: widget.orders.map((o) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  o.orderChannel == 'SHOWROOM' ? Icons.storefront : Icons.receipt,
                                  size: 16,
                                  color: o.orderChannel == 'SHOWROOM' ? Colors.teal : cs.primary,
                                ),
                                const SizedBox(width: 6),
                                SelectableText(
                                  o.orderCode,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(o.recipientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(o.recipientPhone, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                              ],
                            ),
                          ),
                          DataCell(Text(l10n.itemsCount(o.totalItems))),
                          DataCell(Text(
                            widget.formatCurrency(o.finalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )),
                          DataCell(OrderStatusBadge(status: o.orderStatus)),
                          DataCell(OrderStatusBadge(status: o.paymentStatus, isPayment: true)),
                          DataCell(Text(widget.formatDate(o.createdAt), style: const TextStyle(fontSize: 12))),
                          DataCell(
                            FilledButton.tonalIcon(
                              onPressed: () => widget.onOpenDetail(o.id),
                              icon: const Icon(Icons.visibility, size: 16),
                              label: Text(l10n.viewDetails),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
