import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/warehouse_action_menu.dart';
import '../atoms/warehouse_stock_badge.dart';

/// Organism: Tabular view displaying warehouse stock items with thumbnails,
/// SKU, physical/reserved/available counts, health badges, and actions.
class WarehouseTableView extends StatefulWidget {
  final List<InventoryStockItem> items;
  final ValueChanged<InventoryStockItem> onAdjustStock;
  final String Function(double) formatCurrency;
  final String Function(String) resolveImageUrl;

  const WarehouseTableView({
    super.key,
    required this.items,
    required this.onAdjustStock,
    required this.formatCurrency,
    required this.resolveImageUrl,
  });

  @override
  State<WarehouseTableView> createState() => _WarehouseTableViewState();
}

class _WarehouseTableViewState extends State<WarehouseTableView> {
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

    if (widget.items.isEmpty) {
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
                Icon(Icons.warehouse_outlined, size: 54, color: cs.onSurfaceVariant.withAlpha(120)),
                const SizedBox(height: JoppeSpacing.sm),
                Text(
                  l10n.noStockFound,
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
                      horizontalMargin: 16,
                      columnSpacing: 16,
                      dataRowMinHeight: 52,
                      dataRowMaxHeight: 64,
                      columns: [
                        DataColumn(
                          label: Text(l10n.productAndSpec, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.sku, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.unitPrice, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.onHand, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.reserved, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.available, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.reorderThreshold, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.lineTotalValue, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.stockStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        DataColumn(
                          label: Text(l10n.actionCol, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                      rows: widget.items.map((item) {
                        final isAvailableZero = item.stockAvailable <= 0;
                        final isAvailableLow = item.stockAvailable <= item.reorderLevel;
                        final availableColor = isAvailableZero
                            ? cs.error
                            : isAvailableLow
                                ? Colors.orange.shade800
                                : cs.onSurface;

                        return DataRow(
                          cells: [
                            // Product & Spec
                            DataCell(
                              Tooltip(
                                message: '${item.productName} • ${item.variantName}',
                                child: SizedBox(
                                  width: 240,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                                            ? Image.network(
                                                widget.resolveImageUrl(item.thumbnailUrl!),
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) => const Icon(Icons.image, size: 18),
                                              )
                                            : const Icon(Icons.image, size: 18),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              item.variantName,
                                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // SKU
                            DataCell(
                              Tooltip(
                                message: item.sku,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest.withAlpha(120),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.sku,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Unit Price (shows sale price, and list price if discounted)
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.formatCurrency(item.salePrice),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  if (item.listPrice > item.salePrice) ...[
                                    Text(
                                      widget.formatCurrency(item.listPrice),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: cs.onSurfaceVariant.withAlpha(140),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // On Hand
                            DataCell(
                              Text('${item.quantityOnHand}'),
                            ),

                            // Reserved
                            DataCell(
                              Text(
                                '${item.quantityReserved}',
                                style: TextStyle(
                                  color: item.quantityReserved > 0 ? cs.primary : cs.onSurfaceVariant,
                                  fontWeight: item.quantityReserved > 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),

                            // Available
                            DataCell(
                              Tooltip(
                                message: '${item.quantityOnHand} on hand - ${item.quantityReserved} reserved',
                                child: Text(
                                  '${item.stockAvailable}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: availableColor,
                                  ),
                                ),
                              ),
                            ),

                            // Reorder Threshold
                            DataCell(
                              Text('${item.reorderLevel}'),
                            ),

                            // Line Valuation
                            DataCell(
                              Text(
                                widget.formatCurrency(item.quantityOnHand * item.salePrice),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),

                            // Status badge
                            DataCell(
                              WarehouseStockBadge(item: item),
                            ),

                            // Action 3-dot menu
                            DataCell(
                              WarehouseActionMenu(
                                item: item,
                                onAdjustStock: () => widget.onAdjustStock(item),
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
