import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/receipt_status_badge.dart';
import '../atoms/receipt_type_badge.dart';

/// Organism: Responsive tabular view displaying inbound and outbound stock receipts.
class ReceiptTableView extends StatefulWidget {
  final List<GoodReceiptSummary> receipts;
  final ValueChanged<String> onOpenDetail;
  final String Function(double) formatCurrency;
  final String Function(DateTime?) formatDate;

  const ReceiptTableView({
    super.key,
    required this.receipts,
    required this.onOpenDetail,
    required this.formatCurrency,
    required this.formatDate,
  });

  @override
  State<ReceiptTableView> createState() => _ReceiptTableViewState();
}

class _ReceiptTableViewState extends State<ReceiptTableView> {
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

    if (widget.receipts.isEmpty) {
      return Card(
        elevation: 0,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(JoppeShapes.medium),
          side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(JoppeSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 54, color: cs.onSurfaceVariant.withAlpha(120)),
                const SizedBox(height: JoppeSpacing.sm),
                Text(
                  l10n.noReceiptsFound,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(JoppeShapes.medium),
        side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: LayoutBuilder(
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
                      horizontalMargin: 12,
                      columnSpacing: 12,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 56,
                      columns: [
                        DataColumn(
                          label: Text(l10n.receiptCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.movementType, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.partnerOrOrder, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.performerStaff, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.totalItems, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.totalAmount, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.movementStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.placedAtCol, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.actionCol, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                      rows: widget.receipts.map((r) {
                        final partnerLabel = r.isInbound
                            ? (r.supplierName ?? 'Direct Supplier')
                            : (r.orderCode ?? r.orderId ?? 'Online / POS Order');

                        return DataRow(
                          cells: [
                            // Receipt Code
                            DataCell(
                              Text(
                                r.receiptCode,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),

                            // Movement Type
                            DataCell(
                              ReceiptTypeBadge(receiptType: r.receiptType),
                            ),

                            // Partner / Order
                            DataCell(
                              Tooltip(
                                message: r.note ?? partnerLabel,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 180),
                                  child: Text(
                                    partnerLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: r.isOutbound ? FontWeight.w600 : FontWeight.normal,
                                      color: r.isOutbound ? cs.primary : cs.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Staff
                            DataCell(
                              Text(r.staffName, style: const TextStyle(fontSize: 12)),
                            ),

                            // Total Items
                            DataCell(
                              Text('${r.totalItems} pcs'),
                            ),

                            // Total Amount
                            DataCell(
                              Text(
                                widget.formatCurrency(r.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),

                            // Status
                            DataCell(
                              ReceiptStatusBadge(status: r.status),
                            ),

                            // Date
                            DataCell(
                              Text(widget.formatDate(r.createdAt), style: const TextStyle(fontSize: 12)),
                            ),

                            // Action
                            DataCell(
                              FilledButton.tonal(
                                onPressed: () => widget.onOpenDetail(r.id),
                                style: FilledButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                child: Text(l10n.viewDetails),
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
      ),
    );
  }
}
