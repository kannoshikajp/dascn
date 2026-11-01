import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

/// Atom: Cashier catalog product item card with quick tap-to-add action.
class PosProductCard extends StatelessWidget {
  final ProductItem product;
  final ProductVariantSummary variant;
  final VoidCallback onAddToCart;

  const PosProductCard({
    super.key,
    required this.product,
    required this.variant,
    required this.onAddToCart,
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
    final availableStock = variant.quantityOnHand - variant.quantityReserved;
    final isOutOfStock = availableStock <= 0;
    final unitPrice = variant.salePrice > 0 ? variant.salePrice : variant.listPrice;

    return Card(
      elevation: 0,
      color: isOutOfStock
          ? colorScheme.surfaceContainerHighest.withAlpha(60)
          : colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isOutOfStock
              ? colorScheme.outlineVariant.withAlpha(50)
              : colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isOutOfStock ? null : onAddToCart,
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: Brand / SKU & Stock Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      variant.sku,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? colorScheme.errorContainer
                          : (availableStock <= 5 ? Colors.amber.shade100 : Colors.green.shade100),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOutOfStock ? 'Hết hàng' : 'Còn $availableStock',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock
                            ? colorScheme.onErrorContainer
                            : (availableStock <= 5 ? Colors.amber.shade900 : Colors.green.shade900),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: JoppeSpacing.xs),

              // Title
              Text(
                product.productName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                variant.variantName,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Price & Add button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _formatPrice(unitPrice),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock ? colorScheme.outline : colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: JoppeSpacing.xxs),
                  IconButton.filledTonal(
                    onPressed: isOutOfStock ? null : onAddToCart,
                    tooltip: 'Thêm vào đơn',
                    icon: const Icon(Icons.add, size: 16),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
