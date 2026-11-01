import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../localization/dashboard_localizations.dart';
import 'orders/molecules/order_detail_dialog.dart';
import 'orders/molecules/order_filter_bar.dart';
import 'orders/organisms/orders_kpi_row.dart';
import 'orders/organisms/orders_table.dart';

export 'orders/atoms/order_kpi_card.dart';
export 'orders/atoms/order_status_badge.dart';
export 'orders/molecules/order_detail_dialog.dart';
export 'orders/molecules/order_filter_bar.dart';
export 'orders/organisms/orders_kpi_row.dart';
export 'orders/organisms/orders_table.dart';

/// Screen: Orders & Fulfillment management view following Atomic Design principles.
/// Composed of:
/// - Organisms: OrdersKpiRow, OrdersTable (with vertical and horizontal scroll support)
/// - Molecules: OrderFilterBar (multi-toggle pills), OrderDetailDialog
/// - Atoms: OrderKpiCard, OrderStatusBadge
class OrdersView extends StatefulWidget {
  final OrderService orderService;
  final ProductManagementService? productService;
  final UserManagementService? userService;

  const OrdersView({
    super.key,
    required this.orderService,
    this.productService,
    this.userService,
  });

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  List<OrderSummaryModel> _allOrders = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedStatuses = {};
  final Set<String> _selectedPaymentStatuses = {};

  static const List<String> _orderStatuses = [
    'ALL',
    'ACCEPTED',
    'PACKAGING',
    'DELIVERY',
    'SHIPPED',
    'SHOWROOM_BUY',
    'REFUND',
  ];

  static const List<String> _paymentStatuses = [
    'ALL',
    'PAID',
    'UNPAID',
    'REFUND',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await widget.orderService.listAdminOrders(
        status: null,
        paymentStatus: null,
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _allOrders = orders;
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

  List<OrderSummaryModel> get _filteredOrders {
    return _allOrders.where((o) {
      if (_selectedStatuses.isNotEmpty) {
        final upper = o.orderStatus.toUpperCase();
        // Support normalized matching (e.g. DELIVERED == SHIPPED, CONFIRMED/PENDING == ACCEPTED)
        final matches = _selectedStatuses.contains(upper) ||
            (_selectedStatuses.contains('ACCEPTED') && (upper == 'CONFIRMED' || upper == 'PENDING')) ||
            (_selectedStatuses.contains('PACKAGING') && upper == 'PACKING') ||
            (_selectedStatuses.contains('SHIPPED') && upper == 'DELIVERED') ||
            (_selectedStatuses.contains('REFUND') && (upper == 'CANCELLED' || upper == 'REFUNDED'));
        if (!matches) return false;
      }
      if (_selectedPaymentStatuses.isNotEmpty) {
        final upper = o.paymentStatus.toUpperCase();
        final matches = _selectedPaymentStatuses.contains(upper) ||
            (_selectedPaymentStatuses.contains('REFUND') && upper == 'REFUNDED');
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  void _toggleStatus(String st) {
    setState(() {
      if (st == 'ALL') {
        _selectedStatuses.clear();
      } else {
        final upper = st.toUpperCase();
        if (_selectedStatuses.contains(upper)) {
          _selectedStatuses.remove(upper);
        } else {
          _selectedStatuses.add(upper);
        }
      }
    });
  }

  void _togglePaymentStatus(String pst) {
    setState(() {
      if (pst == 'ALL') {
        _selectedPaymentStatuses.clear();
      } else {
        final upper = pst.toUpperCase();
        if (_selectedPaymentStatuses.contains(upper)) {
          _selectedPaymentStatuses.remove(upper);
        } else {
          _selectedPaymentStatuses.add(upper);
        }
      }
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedStatuses.clear();
      _selectedPaymentStatuses.clear();
    });
    _loadOrders();
  }

  String _formatCurrency(double amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} ₫';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openOrderDetail(String orderId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OrderDetailDialog(
        orderId: orderId,
        orderService: widget.orderService,
        onOrderUpdated: _loadOrders,
        formatCurrency: _formatCurrency,
        formatDate: _formatDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(JoppeSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.ordersAndFulfillment,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              IconButton(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                tooltip: l10n.refreshOrders,
              ),
            ],
          ),
          const SizedBox(height: JoppeSpacing.md),
          OrdersKpiRow(
            orders: _allOrders,
            formatCurrency: _formatCurrency,
          ),
          const SizedBox(height: JoppeSpacing.lg),
          OrderFilterBar(
            searchController: _searchController,
            selectedStatuses: _selectedStatuses,
            selectedPaymentStatuses: _selectedPaymentStatuses,
            orderStatuses: _orderStatuses,
            paymentStatuses: _paymentStatuses,
            onToggleStatus: _toggleStatus,
            onTogglePaymentStatus: _togglePaymentStatus,
            onFilter: _loadOrders,
            onReset: _resetFilters,
          ),
          const SizedBox(height: JoppeSpacing.md),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: JoppeSpacing.md),
              child: MaterialBanner(
                content: Text(_error!),
                backgroundColor: cs.errorContainer,
                contentTextStyle: TextStyle(color: cs.onErrorContainer),
                actions: [
                  TextButton(
                    onPressed: _loadOrders,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(JoppeShapes.medium),
                      side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
                    ),
                    child: OrdersTable(
                      orders: _filteredOrders,
                      formatCurrency: _formatCurrency,
                      formatDate: _formatDate,
                      onOpenDetail: _openOrderDetail,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
