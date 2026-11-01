import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: Status badge displaying inventory health status
/// (In Stock, Low Stock with threshold counter, or Out of Stock).
class WarehouseStockBadge extends StatelessWidget {
  final InventoryStockItem item;

  const WarehouseStockBadge({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    Color badgeColor;
    String label;
    IconData icon;

    if (item.isOutOfStock) {
      badgeColor = cs.error;
      label = l10n.outOfStock;
      icon = Icons.error_outline;
    } else if (item.isLowStock) {
      badgeColor = Colors.orange.shade800;
      label = l10n.lowStockBadgeLabel(item.stockAvailable, item.reorderLevel);
      icon = Icons.warning_amber_rounded;
    } else {
      badgeColor = Colors.green.shade700;
      label = l10n.inStock;
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(JoppeShapes.full),
        border: Border.all(color: badgeColor.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
