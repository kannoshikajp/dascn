import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/product_variant_badge.dart';

/// Organism: Renders list of product cards with thumbnails, category tags,
/// formatted pricing, stock health, and actions (edit, toggle status, delete).
class ProductsListView extends StatelessWidget {
  final List<ProductItem> products;
  final ValueChanged<ProductItem> onEditProduct;
  final void Function(String id, bool currentStatus) onToggleStatus;
  final void Function(String id, String name) onDeleteProduct;

  const ProductsListView({
    super.key,
    required this.products,
    required this.onEditProduct,
    required this.onToggleStatus,
    required this.onDeleteProduct,
  });

  String _formatPrice(double price) {
    if (price <= 0) return '0 ₫';
    final intPrice = price.round();
    final str = intPrice.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} ₫';
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const defaultApiUrl = 'http://localhost:8080';
    if (url.startsWith('/')) return '$defaultApiUrl$url';
    return '$defaultApiUrl/$url';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 54, color: cs.onSurfaceVariant.withAlpha(120)),
              const SizedBox(height: JoppeSpacing.sm),
              Text(
                l10n.noProductsFound,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: JoppeSpacing.xs),
      itemBuilder: (context, idx) {
        final p = products[idx];
        final price = p.effectivePrice;

        return Card(
          elevation: 0,
          color: cs.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(JoppeShapes.medium),
            side: BorderSide(color: cs.outlineVariant.withAlpha(70)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(JoppeSpacing.sm),
            child: Row(
              children: [
                // Product Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: cs.surfaceContainerHigh,
                    child: p.thumbnailUrl != null && p.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            _resolveImageUrl(p.thumbnailUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.laptop),
                          )
                        : const Icon(Icons.laptop),
                  ),
                ),
                const SizedBox(width: JoppeSpacing.md),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.productName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: JoppeSpacing.sm),
                          Text(
                            _formatPrice(price),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: JoppeSpacing.sm,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ProductVariantBadge(product: p),
                          Text(
                            p.slug,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (p.categories.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: p.categories.map((c) {
                            return Chip(
                              label: Text(
                                c.isPrimary ? '${c.categoryName} ★' : c.categoryName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: c.isPrimary ? cs.onPrimary : null,
                                ),
                              ),
                              backgroundColor: c.isPrimary ? cs.primary : null,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Row Actions
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.editProduct,
                  onPressed: () => onEditProduct(p),
                ),
                Switch(
                  value: p.isActive,
                  onChanged: (val) => onToggleStatus(p.id, p.isActive),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: cs.error,
                  tooltip: l10n.deleteProduct,
                  onPressed: () => onDeleteProduct(p.id, p.productName),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
