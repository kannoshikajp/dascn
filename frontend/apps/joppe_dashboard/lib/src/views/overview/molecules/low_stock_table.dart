import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../atoms/stock_status_pill.dart';

/// Molecule: Prioritized table of out-of-stock and low-stock catalog products.
class LowStockTable extends StatelessWidget {
  final List<ProductItem> lowStockProducts;
  final VoidCallback onNavigateToCatalog;

  const LowStockTable({
    super.key,
    required this.lowStockProducts,
    required this.onNavigateToCatalog,
  });

  String _formatPrice(double price) {
    if (price <= 0) return '0 ₫';
    final str = price.toStringAsFixed(0);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayList = lowStockProducts.take(5).toList();

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
                Icon(
                  lowStockProducts.isEmpty
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  size: 20,
                  color: lowStockProducts.isEmpty ? Colors.green.shade600 : colorScheme.error,
                ),
                const SizedBox(width: JoppeSpacing.xs),
                Expanded(
                  child: Text(
                    'Cảnh báo tồn kho cần nhập',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: onNavigateToCatalog,
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('Xem kho', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: JoppeSpacing.sm),
            if (lowStockProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: JoppeSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 28),
                    const SizedBox(width: JoppeSpacing.sm),
                    Expanded(
                      child: Text(
                        'Kho hàng an toàn: Toàn bộ sản phẩm đều có lượng tồn kho ổn định (> 10 sản phẩm).',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final p = displayList[idx];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      p.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${p.brandName ?? "Linh kiện"} • ${_formatPrice(p.minPrice)}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                    trailing: StockStatusPill(stockCount: p.totalStock),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
