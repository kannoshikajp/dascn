import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/category_kpi_card.dart';

/// Organism: Responsive row of KPI cards summarizing category metrics.
class CategoryKpiRow extends StatelessWidget {
  final List<CategoryItem> categories;

  const CategoryKpiRow({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final totalCount = categories.length;
    final rootCount = categories.where((c) => c.parentId == null).length;
    final activeCount = categories.where((c) => c.isActive).length;
    final totalProducts = categories.fold(0, (sum, c) => sum + c.productCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final cardWidth = isCompact
            ? (constraints.maxWidth - JoppeSpacing.md) / 2
            : (constraints.maxWidth - (JoppeSpacing.md * 3)) / 4;

        return Wrap(
          spacing: JoppeSpacing.md,
          runSpacing: JoppeSpacing.md,
          children: [
            CategoryKpiCard(
              title: l10n.totalCategoriesKpi,
              value: totalCount.toString(),
              icon: Icons.category_outlined,
              color: cs.primary,
              width: cardWidth,
            ),
            CategoryKpiCard(
              title: l10n.rootCategoriesKpi,
              value: rootCount.toString(),
              icon: Icons.folder_open,
              color: Colors.blue.shade700,
              width: cardWidth,
            ),
            CategoryKpiCard(
              title: l10n.activeCategoriesKpi,
              value: activeCount.toString(),
              icon: Icons.check_circle_outline,
              color: Colors.green.shade700,
              width: cardWidth,
            ),
            CategoryKpiCard(
              title: l10n.linkedProductsKpi,
              value: totalProducts.toString(),
              icon: Icons.inventory_2_outlined,
              color: Colors.amber.shade800,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }
}
