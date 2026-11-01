import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

class DailyMetricPoint {
  final String dateLabel;
  final int orderCount;
  final double totalRevenue;

  const DailyMetricPoint({
    required this.dateLabel,
    required this.orderCount,
    required this.totalRevenue,
  });
}

enum MetricDisplayMode {
  orders,
  revenue,
}

/// Molecule: Order velocity & sales trend visualization powered by fl_chart.
/// Follows dataviz principles:
/// - Single y-scale (segmented toggle between orders & revenue)
/// - Thin marks (16px wide), 4px rounded data-ends anchored to baseline
/// - Recessive grid lines, clear baseline
/// - Interactive hover tooltip layer with exact currency formatting
class SalesTrendChart extends StatefulWidget {
  final List<OrderSummaryModel> orders;
  final String title;

  const SalesTrendChart({
    super.key,
    required this.orders,
    this.title = 'Biểu đồ tăng trưởng bán hàng (7 ngày)',
  });

  @override
  State<SalesTrendChart> createState() => _SalesTrendChartState();
}

class _SalesTrendChartState extends State<SalesTrendChart> {
  MetricDisplayMode _displayMode = MetricDisplayMode.orders;

  List<DailyMetricPoint> _aggregateLast7Days() {
    final now = DateTime.now();
    final points = <DailyMetricPoint>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final dayOrders = widget.orders.where((o) {
        if (o.createdAt == null) return false;
        return o.createdAt!.isAfter(dayStart) && o.createdAt!.isBefore(dayEnd);
      }).toList();

      final count = dayOrders.length;
      final revenue = dayOrders.fold<double>(0.0, (sum, o) => sum + o.finalAmount);
      final label = '${day.day}/${day.month}';

      points.add(DailyMetricPoint(
        dateLabel: label,
        orderCount: count,
        totalRevenue: revenue,
      ));
    }

    return points;
  }

  String _formatCurrency(double amount) {
    if (amount <= 0) return '0 ₫';
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} Tr ₫';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} k ₫';
    }
    return '${amount.toStringAsFixed(0)} ₫';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final points = _aggregateLast7Days();

    final isRevenueMode = _displayMode == MetricDisplayMode.revenue;
    final maxOrderCount = points.map((p) => p.orderCount).fold(0, math.max);
    final maxRevenueMillions = points.map((p) => p.totalRevenue / 1000000).fold(0.0, math.max);

    final double maxY = isRevenueMode
        ? math.max(5.0, (maxRevenueMillions * 1.25).ceilToDouble())
        : math.max(4.0, (maxOrderCount * 1.25).ceilToDouble());

    final double interval = isRevenueMode
        ? (maxY / 4).clamp(1.0, 50.0)
        : (maxY / 4).clamp(1.0, 20.0);

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
            // Header: Title & Single Metric Toggle
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: JoppeSpacing.xs),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: JoppeSpacing.xs),
                SegmentedButton<MetricDisplayMode>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: MetricDisplayMode.orders,
                      label: Text('Số đơn', style: TextStyle(fontSize: 11)),
                    ),
                    ButtonSegment(
                      value: MetricDisplayMode.revenue,
                      label: Text('Doanh thu', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                  selected: {_displayMode},
                  onSelectionChanged: (selected) {
                    setState(() => _displayMode = selected.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: JoppeSpacing.md),

            // fl_chart BarChart Container
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outlineVariant.withAlpha(45),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withAlpha(100),
                        width: 1,
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value > maxY) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            isRevenueMode
                                ? '${value.toStringAsFixed(0)}M'
                                : value.toStringAsFixed(0),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              points[idx].dateLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colorScheme.inverseSurface,
                      tooltipBorderRadius: BorderRadius.circular(6),
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex < 0 || groupIndex >= points.length) {
                          return null;
                        }
                        final p = points[groupIndex];
                        return BarTooltipItem(
                          '${p.dateLabel}\n',
                          TextStyle(
                            color: colorScheme.onInverseSurface.withAlpha(200),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: '${p.orderCount} đơn • ${_formatCurrency(p.totalRevenue)}',
                              style: TextStyle(
                                color: colorScheme.onInverseSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  barGroups: List.generate(points.length, (idx) {
                    final p = points[idx];
                    final double val = isRevenueMode
                        ? (p.totalRevenue / 1000000)
                        : p.orderCount.toDouble();

                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: val,
                          width: 16,
                          color: val > 0
                              ? colorScheme.primary
                              : colorScheme.primary.withAlpha(40),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
