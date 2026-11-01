import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/warehouse_kpi_card.dart';

/// Organism: Responsive row of KPI cards summarizing warehouse stock metrics.
class WarehouseKpiRow extends StatelessWidget {
  final List<InventoryStockItem> stockItems;
  final String Function(double) formatCurrency;

  const WarehouseKpiRow({
    super.key,
    required this.stockItems,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final totalVariants = stockItems.length;
    final lowStockCount = stockItems.where((i) => i.isLowStock).length;
    final outOfStockCount = stockItems.where((i) => i.isOutOfStock).length;
    final totalValuation = stockItems.fold(
      0.0,
      (sum, i) => sum + (i.quantityOnHand * i.salePrice),
    );

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
            WarehouseKpiCard(
              title: l10n.totalVariants,
              value: '$totalVariants',
              icon: Icons.memory,
              color: cs.primary,
              width: cardWidth,
            ),
            WarehouseKpiCard(
              title: l10n.lowStockAlert,
              value: '$lowStockCount',
              icon: Icons.warning_amber_rounded,
              color: Colors.orange.shade800,
              width: cardWidth,
            ),
            WarehouseKpiCard(
              title: l10n.outOfStock,
              value: '$outOfStockCount',
              icon: Icons.error_outline,
              color: cs.error,
              width: cardWidth,
            ),
            WarehouseKpiCard(
              title: l10n.warehouseValuation,
              value: formatCurrency(totalValuation),
              icon: Icons.account_balance_outlined,
              color: Colors.green.shade700,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }
}
