import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/order_kpi_card.dart';

/// Organism: Responsive row of KPI cards summarizing orders state.
class OrdersKpiRow extends StatelessWidget {
  final List<OrderSummaryModel> orders;
  final String Function(double) formatCurrency;

  const OrdersKpiRow({
    super.key,
    required this.orders,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final pendingCount = orders.where((o) =>
        o.orderStatus == 'ACCEPTED' ||
        o.orderStatus == 'PACKAGING' ||
        o.orderStatus == 'PENDING' ||
        o.orderStatus == 'CONFIRMED').length;
    final shippingCount = orders.where((o) => o.orderStatus == 'DELIVERY' || o.orderStatus == 'SHIPPED').length;
    final deliveredOrders = orders.where((o) =>
        o.orderStatus == 'SHIPPED' ||
        o.orderStatus == 'SHOWROOM_BUY' ||
        o.orderStatus == 'DELIVERED');
    final deliveredRevenue = deliveredOrders.fold(0.0, (sum, o) => sum + o.finalAmount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        return Wrap(
          spacing: JoppeSpacing.md,
          runSpacing: JoppeSpacing.md,
          children: [
            OrderKpiCard(
              title: l10n.totalOrdersKpi,
              value: orders.length.toString(),
              icon: Icons.receipt_long,
              color: cs.primary,
              width: isCompact ? (constraints.maxWidth - JoppeSpacing.md) / 2 : 200,
            ),
            OrderKpiCard(
              title: l10n.pendingActionKpi,
              value: pendingCount.toString(),
              icon: Icons.pending_actions,
              color: Colors.orange,
              width: isCompact ? (constraints.maxWidth - JoppeSpacing.md) / 2 : 200,
            ),
            OrderKpiCard(
              title: l10n.inTransitKpi,
              value: shippingCount.toString(),
              icon: Icons.local_shipping,
              color: Colors.purple,
              width: isCompact ? (constraints.maxWidth - JoppeSpacing.md) / 2 : 200,
            ),
            OrderKpiCard(
              title: l10n.deliveredRevenueKpi,
              value: formatCurrency(deliveredRevenue),
              icon: Icons.payments,
              color: Colors.green,
              width: isCompact ? constraints.maxWidth : 260,
            ),
          ],
        );
      },
    );
  }
}
