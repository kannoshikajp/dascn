import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../atoms/overview_kpi_tile.dart';

/// Organism: Responsive grid of 4 core operational business KPIs.
class OverviewKpiRow extends StatelessWidget {
  final double totalRevenue;
  final int totalOrders;
  final int pendingOrders;
  final int totalProducts;
  final int activeProducts;
  final int totalUsers;
  final int activeUsers;
  final VoidCallback onNavigateToOrders;
  final VoidCallback onNavigateToProducts;
  final VoidCallback onNavigateToUsers;

  const OverviewKpiRow({
    super.key,
    required this.totalRevenue,
    required this.totalOrders,
    required this.pendingOrders,
    required this.totalProducts,
    required this.activeProducts,
    required this.totalUsers,
    required this.activeUsers,
    required this.onNavigateToOrders,
    required this.onNavigateToProducts,
    required this.onNavigateToUsers,
  });

  String _formatRevenue(double amount) {
    if (amount <= 0) return '0 ₫';
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(2)} Tỷ ₫';
    }
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
    final colorScheme = Theme.of(context).colorScheme;

    return GridView(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisExtent: 130,
        crossAxisSpacing: JoppeSpacing.md,
        mainAxisSpacing: JoppeSpacing.md,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        OverviewKpiTile(
          title: 'Tổng doanh thu',
          value: _formatRevenue(totalRevenue),
          subtitle: '$totalOrders đơn hàng ghi nhận',
          icon: Icons.payments_outlined,
          color: Colors.green.shade600,
          onTap: onNavigateToOrders,
        ),
        OverviewKpiTile(
          title: 'Customer Orders',
          value: '$totalOrders',
          subtitle: '$pendingOrders đơn chờ xử lý',
          icon: Icons.receipt_long_outlined,
          color: Colors.indigo.shade600,
          onTap: onNavigateToOrders,
        ),
        OverviewKpiTile(
          title: 'Total Products',
          value: '$totalProducts',
          subtitle: '$activeProducts mặt hàng đang bán',
          icon: Icons.inventory_2_outlined,
          color: colorScheme.primary,
          onTap: onNavigateToProducts,
        ),
        OverviewKpiTile(
          title: 'System Users',
          value: '$totalUsers',
          subtitle: '$activeUsers tài khoản hoạt động',
          icon: Icons.people_outline,
          color: colorScheme.secondary,
          onTap: onNavigateToUsers,
        ),
      ],
    );
  }
}
