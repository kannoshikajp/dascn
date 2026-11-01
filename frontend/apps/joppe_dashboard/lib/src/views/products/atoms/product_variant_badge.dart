import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: Renders SKU chip and parent/variant relationship badge.
class ProductVariantBadge extends StatelessWidget {
  final ProductItem product;

  const ProductVariantBadge({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (product.sku.isNotEmpty || (product.versionCode != null && product.versionCode!.isNotEmpty))
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              product.sku.isNotEmpty ? product.sku : product.versionCode!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        if (product.parentSku != null && product.parentSku!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.amber.shade700, width: 1),
            ),
            child: Text(
              l10n.variantOfBadge(product.parentSku!),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
            ),
          )
        else if (product.variants.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.teal.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.teal.shade700, width: 1),
            ),
            child: Text(
              l10n.parentVariantBadge(product.variants.length),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
          ),
      ],
    );
  }
}
