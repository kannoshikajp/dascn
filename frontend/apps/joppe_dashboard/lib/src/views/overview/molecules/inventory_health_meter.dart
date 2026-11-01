import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

/// Molecule: Segmented stock health proportion bar following dataviz specs (2px gap, status colors).
class InventoryHealthMeter extends StatelessWidget {
  final int totalCount;
  final int healthyCount;
  final int lowStockCount;
  final int outOfStockCount;
  final VoidCallback? onManageStock;

  const InventoryHealthMeter({
    super.key,
    required this.totalCount,
    required this.healthyCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    this.onManageStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = totalCount > 0 ? totalCount : 1;

    final healthyRatio = (healthyCount / total).clamp(0.0, 1.0);
    final lowRatio = (lowStockCount / total).clamp(0.0, 1.0);
    final outRatio = (outOfStockCount / total).clamp(0.0, 1.0);

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
                Icon(Icons.pie_chart_outline_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: JoppeSpacing.xs),
                Expanded(
                  child: Text(
                    'Tỷ lệ sức khỏe kho hàng',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onManageStock != null)
                  TextButton.icon(
                    onPressed: onManageStock,
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('Kho hàng', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: JoppeSpacing.sm),
            // Segmented proportion bar with 2px surface gaps
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (healthyCount > 0)
                      Expanded(
                        flex: (healthyRatio * 1000).toInt(),
                        child: Container(color: Colors.green.shade600),
                      ),
                    if (lowStockCount > 0) ...[
                      if (healthyCount > 0) Container(width: 2, color: colorScheme.surface),
                      Expanded(
                        flex: (lowRatio * 1000).toInt(),
                        child: Container(color: Colors.amber.shade700),
                      ),
                    ],
                    if (outOfStockCount > 0) ...[
                      if (healthyCount > 0 || lowStockCount > 0)
                        Container(width: 2, color: colorScheme.surface),
                      Expanded(
                        flex: (outRatio * 1000).toInt(),
                        child: Container(color: colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: JoppeSpacing.md),
            // Legend
            Wrap(
              spacing: JoppeSpacing.md,
              runSpacing: JoppeSpacing.xs,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildLegendItem(
                  context,
                  color: Colors.green.shade600,
                  label: 'Đủ hàng (>10)',
                  count: healthyCount,
                  percentage: (healthyRatio * 100).toStringAsFixed(0),
                ),
                _buildLegendItem(
                  context,
                  color: Colors.amber.shade700,
                  label: 'Sắp hết (1-10)',
                  count: lowStockCount,
                  percentage: (lowRatio * 100).toStringAsFixed(0),
                ),
                _buildLegendItem(
                  context,
                  color: colorScheme.error,
                  label: 'Hết hàng (0)',
                  count: outOfStockCount,
                  percentage: (outRatio * 100).toStringAsFixed(0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required int count,
    required String percentage,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
            ),
            Text(
              '$count ($percentage%)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
