import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

/// Molecule: Compact list of recent customer orders with fulfillment status.
class RecentOrdersCard extends StatelessWidget {
  final List<OrderSummaryModel> orders;
  final VoidCallback onNavigateToOrders;

  const RecentOrdersCard({
    super.key,
    required this.orders,
    required this.onNavigateToOrders,
  });

  String _formatCurrency(double amount) {
    if (amount <= 0) return '0 ₫';
    final str = amount.toStringAsFixed(0);
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

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green.shade600;
      case 'SHIPPING':
        return Colors.blue.shade600;
      case 'CONFIRMED':
        return Colors.indigo.shade600;
      case 'CANCELLED':
        return colorScheme.error;
      case 'PENDING':
      default:
        return Colors.amber.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recent = orders.take(5).toList();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(120)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(JoppeSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 20, color: colorScheme.primary),
                const SizedBox(width: JoppeSpacing.xs),
                Expanded(
                  child: Text(
                    'Đơn hàng mới nhất',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: onNavigateToOrders,
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('Xem tất cả', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: JoppeSpacing.sm),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: JoppeSpacing.lg),
                child: Center(
                  child: Text(
                    'Chưa có đơn hàng nào',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final order = recent[idx];
                  final statusColor = _getStatusColor(order.orderStatus, colorScheme);

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.orderCode.isNotEmpty ? order.orderCode : 'ORD-#${order.id.substring(0, 6)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: JoppeSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.orderStatus,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${order.recipientName} • ${order.totalItems} sản phẩm',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                    trailing: Text(
                      _formatCurrency(order.finalAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
