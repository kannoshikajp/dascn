import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../atoms/pos_product_card.dart';

/// Organism: Interactive hardware catalog grid for POS Cashier with search & instant filtering.
class PosCatalogView extends StatefulWidget {
  final List<ProductItem> products;
  final void Function(ProductItem product, ProductVariantSummary variant) onVariantSelected;

  const PosCatalogView({
    super.key,
    required this.products,
    required this.onVariantSelected,
  });

  @override
  State<PosCatalogView> createState() => _PosCatalogViewState();
}

class _PosCatalogViewState extends State<PosCatalogView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Extract unique category names
    final categories = <String>{};
    for (final p in widget.products) {
      for (final c in p.categories) {
        categories.add(c.categoryName);
      }
    }

    // Filter matching variants
    final List<MapEntry<ProductItem, ProductVariantSummary>> pairs = [];
    final q = _searchQuery.toLowerCase();

    for (final p in widget.products) {
      if (_selectedCategory != null) {
        final hasCat = p.categories.any((c) => c.categoryName == _selectedCategory);
        if (!hasCat) continue;
      }

      for (final v in p.variants) {
        if (!v.isActive) continue;
        if (q.isNotEmpty) {
          final matchesProduct = p.productName.toLowerCase().contains(q);
          final matchesSku = v.sku.toLowerCase().contains(q);
          final matchesVariant = v.variantName.toLowerCase().contains(q);
          final matchesBrand = (p.brandName ?? '').toLowerCase().contains(q);
          if (!matchesProduct && !matchesSku && !matchesVariant && !matchesBrand) {
            continue;
          }
        }
        pairs.add(MapEntry(p, v));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search & Category Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm, quét mã SKU...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withAlpha(50),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
          ],
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: JoppeSpacing.sm),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả', style: TextStyle(fontSize: 11)),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: JoppeSpacing.xs),
                ...categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: JoppeSpacing.xs),
                    child: ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 11)),
                      selected: _selectedCategory == cat,
                      onSelected: (_) => setState(() => _selectedCategory = (_selectedCategory == cat ? null : cat)),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: JoppeSpacing.md),

        // Product Cards Grid
        Expanded(
          child: pairs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: colorScheme.outline),
                      const SizedBox(height: JoppeSpacing.sm),
                      Text(
                        'Không tìm thấy sản phẩm phù hợp',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 170,
                    crossAxisSpacing: JoppeSpacing.sm,
                    mainAxisSpacing: JoppeSpacing.sm,
                  ),
                  itemCount: pairs.length,
                  itemBuilder: (context, idx) {
                    final pair = pairs[idx];
                    return PosProductCard(
                      product: pair.key,
                      variant: pair.value,
                      onAddToCart: () => widget.onVariantSelected(pair.key, pair.value),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
