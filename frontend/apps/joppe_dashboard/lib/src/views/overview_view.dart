import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../localization/dashboard_localizations.dart';
import 'overview/molecules/inventory_health_meter.dart';
import 'overview/molecules/low_stock_table.dart';
import 'overview/molecules/recent_orders_card.dart';
import 'overview/molecules/sales_trend_chart.dart';
import 'overview/organisms/overview_header.dart';
import 'overview/organisms/overview_kpi_row.dart';

/// Screen: Overview (Tổng quan) built following Atomic Design principles.
/// Composed of:
/// - Organisms: OverviewHeader, OverviewKpiRow
/// - Molecules: SalesTrendChart, InventoryHealthMeter, RecentOrdersCard, LowStockTable
/// - Atoms: OverviewKpiTile, StockStatusPill
class OverviewView extends StatefulWidget {
  final UserManagementService userService;
  final RbacManagementService rbacService;
  final CategoryManagementService categoryService;
  final ProductManagementService productService;
  final OrderService? orderService;
  final AnalyticsService? analyticsService;
  final VoidCallback onNavigateToUsers;
  final VoidCallback onNavigateToCategories;
  final VoidCallback onNavigateToProducts;
  final VoidCallback onNavigateToRbac;
  final VoidCallback? onNavigateToOrders;
  final VoidCallback? onNavigateToInventory;
  final VoidCallback? onNavigateToReceipts;

  const OverviewView({
    super.key,
    required this.userService,
    required this.rbacService,
    required this.categoryService,
    required this.productService,
    this.orderService,
    this.analyticsService,
    required this.onNavigateToUsers,
    required this.onNavigateToCategories,
    required this.onNavigateToProducts,
    required this.onNavigateToRbac,
    this.onNavigateToOrders,
    this.onNavigateToInventory,
    this.onNavigateToReceipts,
  });

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalProducts = 0;
  int _activeProducts = 0;
  int _outOfStockCount = 0;
  int _lowStockCount = 0;
  int _healthyCount = 0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  double _totalRevenue = 0.0;

  List<ProductItem> _lowStockProducts = [];
  List<OrderSummaryModel> _orders = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = <Future<dynamic>>[
        widget.userService.listUsers(),
        widget.productService.listProducts(),
      ];

      if (widget.orderService != null) {
        futures.add(widget.orderService!.listAdminOrders());
      }

      final results = await Future.wait(futures);

      final users = results[0] as List<UserSummary>;
      final products = results[1] as List<ProductItem>;
      final orders = widget.orderService != null && results.length > 2
          ? (results[2] as List<OrderSummaryModel>)
          : <OrderSummaryModel>[];

      final outOfStock = products.where((p) => p.totalStock <= 0).toList();
      final lowStock = products.where((p) => p.totalStock > 0 && p.totalStock <= 10).toList();
      final healthy = products.where((p) => p.totalStock > 10).toList();

      final pendingCount = orders.where((o) => o.orderStatus == 'PENDING').length;
      final revenue = orders.fold<double>(0.0, (sum, o) => sum + o.finalAmount);

      // Try server-aggregated analytics endpoint if available
      double effectiveRevenue = revenue;
      int effectivePending = pendingCount;
      int effectiveTotalOrders = orders.length;
      int effectiveHealthy = healthy.length;
      int effectiveLowStock = lowStock.length;
      int effectiveOutOfStock = outOfStock.length;
      int effectiveTotalProducts = products.length;
      int effectiveActiveProducts = products.where((p) => p.isActive).length;

      if (widget.analyticsService != null) {
        try {
          final analytics = await widget.analyticsService!.getOverview();
          effectiveRevenue = analytics.revenueSummary.totalRevenue;
          effectivePending = analytics.revenueSummary.pendingOrders;
          effectiveTotalOrders = analytics.revenueSummary.totalOrders;
          effectiveHealthy = analytics.inventoryHealth.healthyCount;
          effectiveLowStock = analytics.inventoryHealth.lowStockCount;
          effectiveOutOfStock = analytics.inventoryHealth.outOfStockCount;
          effectiveTotalProducts = analytics.inventoryHealth.totalProducts;
          effectiveActiveProducts = analytics.inventoryHealth.activeProducts;
        } catch (_) {
          // Keep calculated fallbacks
        }
      }

      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _activeUsers = users.where((u) => u.isActive).length;

          _totalProducts = effectiveTotalProducts;
          _activeProducts = effectiveActiveProducts;

          _outOfStockCount = effectiveOutOfStock;
          _lowStockCount = effectiveLowStock;
          _healthyCount = effectiveHealthy;
          _lowStockProducts = [...outOfStock, ...lowStock];

          _orders = orders;
          _totalOrders = effectiveTotalOrders;
          _pendingOrders = effectivePending;
          _totalRevenue = effectiveRevenue;

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: colorScheme.error),
            const SizedBox(height: JoppeSpacing.md),
            Text('Could not load statistics: $_error'),
            const SizedBox(height: JoppeSpacing.md),
            FilledButton(
              onPressed: _fetchStats,
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(JoppeSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Organism
              OverviewHeader(
                title: 'Joppe Admin Operations Center',
                subtitle: l10n.isVi
                    ? 'Theo dõi chỉ số bán hàng, tồn kho và xử lý đơn hàng theo thời gian thực'
                    : 'Real-time sales tracking, inventory control, and order fulfillment',
                onRefresh: _fetchStats,
                isRefreshing: _isLoading,
              ),
              const SizedBox(height: JoppeSpacing.lg),

              // 2. Core Business KPI Row Organism
              OverviewKpiRow(
                totalRevenue: _totalRevenue,
                totalOrders: _totalOrders,
                pendingOrders: _pendingOrders,
                totalProducts: _totalProducts,
                activeProducts: _activeProducts,
                totalUsers: _totalUsers,
                activeUsers: _activeUsers,
                onNavigateToOrders: widget.onNavigateToOrders ?? () {},
                onNavigateToProducts: widget.onNavigateToProducts,
                onNavigateToUsers: widget.onNavigateToUsers,
              ),
              const SizedBox(height: JoppeSpacing.lg),

              // 3. Visual Analytics Section (Sales Trend & Inventory Health Meter)
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: SalesTrendChart(orders: _orders),
                    ),
                    const SizedBox(width: JoppeSpacing.md),
                    Expanded(
                      flex: 4,
                      child: InventoryHealthMeter(
                        totalCount: _totalProducts,
                        healthyCount: _healthyCount,
                        lowStockCount: _lowStockCount,
                        outOfStockCount: _outOfStockCount,
                        onManageStock: widget.onNavigateToInventory ?? widget.onNavigateToProducts,
                      ),
                    ),
                  ],
                )
              else ...[
                SalesTrendChart(orders: _orders),
                const SizedBox(height: JoppeSpacing.md),
                InventoryHealthMeter(
                  totalCount: _totalProducts,
                  healthyCount: _healthyCount,
                  lowStockCount: _lowStockCount,
                  outOfStockCount: _outOfStockCount,
                  onManageStock: widget.onNavigateToInventory ?? widget.onNavigateToProducts,
                ),
              ],
              const SizedBox(height: JoppeSpacing.lg),

              // 4. Operational Tables Section (Low Stock Alerts & Recent Orders)
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: LowStockTable(
                        lowStockProducts: _lowStockProducts,
                        onNavigateToCatalog: widget.onNavigateToProducts,
                      ),
                    ),
                    const SizedBox(width: JoppeSpacing.md),
                    Expanded(
                      flex: 5,
                      child: RecentOrdersCard(
                        orders: _orders,
                        onNavigateToOrders: widget.onNavigateToOrders ?? () {},
                      ),
                    ),
                  ],
                )
              else ...[
                LowStockTable(
                  lowStockProducts: _lowStockProducts,
                  onNavigateToCatalog: widget.onNavigateToProducts,
                ),
                const SizedBox(height: JoppeSpacing.md),
                RecentOrdersCard(
                  orders: _orders,
                  onNavigateToOrders: widget.onNavigateToOrders ?? () {},
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
