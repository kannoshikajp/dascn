import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../models/pos_cart_item.dart';

/// Atom: Single line item in the POS Cashier Register Cart with quantity increment/decrement.
class PosCartItemRow extends StatelessWidget {
  final PosCartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const PosCartItemRow({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: JoppeSpacing.xs),
      child: Container(
        padding: const EdgeInsets.all(JoppeSpacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${item.variantName} • ${_formatPrice(item.unitPrice)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  color: colorScheme.error,
                  tooltip: 'Xóa khỏi đơn',
                ),
              ],
            ),
            const SizedBox(height: JoppeSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Qty Controller (- / qty / +)
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          if (item.quantity > 1) {
                            onQuantityChanged(item.quantity - 1);
                          } else {
                            onRemove();
                          }
                        },
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(Icons.remove, size: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      InkWell(
                        onTap: item.quantity < item.stockAvailable
                            ? () => onQuantityChanged(item.quantity + 1)
                            : null,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: item.quantity < item.stockAvailable
                                ? colorScheme.onSurface
                                : colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Line total
                Text(
                  _formatPrice(item.lineTotal),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
