import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../utils/receipt_printer_helper.dart';
import 'models/pos_cart_item.dart';
import 'molecules/pos_checkout_panel.dart';
import 'molecules/pos_qr_payment_dialog.dart';
import 'organisms/pos_catalog_view.dart';
import 'organisms/pos_register_drawer.dart';

/// Screen: Dedicated POS Cashier Application.
/// Built using Atomic Design:
/// - Screen: PosCashierView (split catalog vs cashier register)
/// - Organisms: PosCatalogView, PosRegisterDrawer
/// - Molecules: PosCheckoutPanel, PosCustomerBar, PosVnPayQrDialog
/// - Atoms: PosProductCard, PosCartItemRow
class PosCashierView extends StatefulWidget {
  final OrderService orderService;
  final ProductManagementService productService;
  final UserManagementService userService;
  final VnPayService? vnPayService;

  const PosCashierView({
    super.key,
    required this.orderService,
    required this.productService,
    required this.userService,
    this.vnPayService,
  });

  @override
  State<PosCashierView> createState() => _PosCashierViewState();
}

class _PosCashierViewState extends State<PosCashierView> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  List<ProductItem> _products = [];
  List<UserSummary> _customers = [];

  // Register Cart State
  final List<PosCartItem> _cartItems = [];

  // Customer State
  bool _isWalkIn = true;
  UserSummary? _selectedCustomer;
  final TextEditingController _nameCtrl = TextEditingController(text: 'Khách lẻ vãng lai');
  final TextEditingController _phoneCtrl = TextEditingController();

  // Delivery & Payment State
  bool _isCounterPickup = true;
  double _shippingFee = 0.0;
  PosPaymentMethod _paymentMethod = PosPaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.productService.listProducts(isActive: true),
        widget.userService.listUsers(isActive: true),
      ]);

      if (mounted) {
        setState(() {
          _products = results[0] as List<ProductItem>;
          _customers = results[1] as List<UserSummary>;
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

  void _onAddToCart(ProductItem product, ProductVariantSummary variant) {
    final available = variant.quantityOnHand - variant.quantityReserved;
    if (available <= 0) {
      _showSnackbar('Sản phẩm đã hết hàng!');
      return;
    }

    final price = variant.salePrice > 0 ? variant.salePrice : variant.listPrice;
    final existingIdx = _cartItems.indexWhere((i) => i.variantId == variant.id);

    setState(() {
      if (existingIdx >= 0) {
        final existing = _cartItems[existingIdx];
        if (existing.quantity < available) {
          existing.quantity += 1;
        } else {
          _showSnackbar('Không thể thêm quá số lượng tồn kho ($available)');
        }
      } else {
        _cartItems.add(PosCartItem(
          variantId: variant.id,
          productId: product.id,
          productName: product.productName,
          variantName: variant.variantName,
          sku: variant.sku,
          variantCode: variant.variantCode,
          thumbnailUrl: variant.thumbnailUrl,
          unitPrice: price,
          quantity: 1,
          stockAvailable: available,
        ));
      }
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  double get _subtotal => _cartItems.fold(0.0, (sum, i) => sum + i.lineTotal);

  Future<void> _handleCheckout() async {
    if (_cartItems.isEmpty) return;

    final customerName = _nameCtrl.text.trim().isEmpty ? 'Khách lẻ vãng lai' : _nameCtrl.text.trim();
    final customerPhone = _phoneCtrl.text.trim().isEmpty ? '0900000000' : _phoneCtrl.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final items = _cartItems.map((i) => {
        'variantId': i.variantId,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
        if (i.serialNumbers.isNotEmpty) 'serialNumbers': i.serialNumbers,
      }).toList();

      final isQr = _paymentMethod == PosPaymentMethod.qrTransfer;

      final createdOrder = await widget.orderService.createAdminOrder(
        userId: _isWalkIn ? null : _selectedCustomer?.id,
        recipientName: customerName,
        recipientPhone: customerPhone,
        shippingAddress: _isCounterPickup ? 'Nhận hàng tại quầy (Counter Pickup)' : 'Giao hàng tận nơi',
        shippingFee: _isCounterPickup ? 0.0 : _shippingFee,
        orderStatus: _isCounterPickup ? 'SHOWROOM_BUY' : 'ACCEPTED',
        paymentStatus: isQr ? 'UNPAID' : 'PAID',
        items: items,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _cartItems.clear();
        });

        if (isQr && widget.vnPayService != null) {
          try {
            final vnpayInfo = await widget.vnPayService!.createPaymentUrl(
              orderId: createdOrder.id,
              bankCode: 'NCB',
            );
            if (mounted) {
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => PosVnPayQrDialog(
                  order: createdOrder,
                  vnpayInfo: vnpayInfo,
                  orderService: widget.orderService,
                  onPaymentCompleted: () {
                    // Dialog already renders success receipt & print options.
                  },
                ),
              );
            }
          } catch (_) {
            _showOrderReceiptSuccess(createdOrder);
          }
        } else {
          _showOrderReceiptSuccess(createdOrder);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackbar('Lỗi thanh toán: $e');
      }
    }
  }

  void _showOrderReceiptSuccess(OrderDetailModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
        title: const Text('Thanh toán thành công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã đơn hàng: ${order.orderCode}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Khách hàng: ${order.recipientName} (${order.recipientPhone})'),
            const SizedBox(height: 4),
            Text('Tổng tiền thanh toán: ${order.finalAmount.toStringAsFixed(0)} ₫',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 4),
            Text('Trạng thái: ${order.orderStatus} • ${order.paymentStatus}'),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => printReceipt(context, order),
            icon: const Icon(Icons.print_outlined),
            label: const Text('In hóa đơn'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tạo đơn tiếp theo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            Text('Lỗi tải dữ liệu bán hàng: $_error'),
            const SizedBox(height: JoppeSpacing.md),
            FilledButton(onPressed: _loadData, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        return Padding(
          padding: const EdgeInsets.all(JoppeSpacing.md),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left (60%): Hardware Catalog & Fast Item Selector
                    Expanded(
                      flex: 6,
                      child: PosCatalogView(
                        products: _products,
                        onVariantSelected: _onAddToCart,
                      ),
                    ),
                    const SizedBox(width: JoppeSpacing.md),

                    // Right (40%): Live Cashier Register Drawer with Total Money to Pay
                    Expanded(
                      flex: 4,
                      child: PosRegisterDrawer(
                        cartItems: _cartItems,
                        onItemQuantityChanged: (_) => setState(() {}),
                        onItemRemoved: (item) => setState(() => _cartItems.remove(item)),
                        onClearCart: () => setState(() => _cartItems.clear()),
                        isWalkIn: _isWalkIn,
                        onWalkInChanged: (w) => setState(() {
                          _isWalkIn = w;
                          if (w) {
                            _nameCtrl.text = 'Khách lẻ vãng lai';
                            _phoneCtrl.clear();
                          }
                        }),
                        customers: _customers,
                        selectedCustomer: _selectedCustomer,
                        onCustomerSelected: (c) => setState(() {
                          _selectedCustomer = c;
                          if (c != null) {
                            _nameCtrl.text = c.fullName;
                            _phoneCtrl.text = c.phoneNumber ?? '';
                          }
                        }),
                        nameController: _nameCtrl,
                        phoneController: _phoneCtrl,
                        subtotal: _subtotal,
                        shippingFee: _shippingFee,
                        paymentMethod: _paymentMethod,
                        onPaymentMethodChanged: (m) => setState(() => _paymentMethod = m),
                        isCounterPickup: _isCounterPickup,
                        onDeliveryPresetChanged: (c) => setState(() {
                          _isCounterPickup = c;
                          _shippingFee = c ? 0.0 : 30000.0;
                        }),
                        onCheckout: _handleCheckout,
                        isSubmitting: _isSubmitting,
                      ),
                    ),
                  ],
                )
              : DefaultTabController(
                  length: 2,
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Bán hàng tại quầy (POS)'),
                      bottom: TabBar(
                        tabs: [
                          const Tab(text: 'Chọn sản phẩm', icon: Icon(Icons.grid_view)),
                          Tab(text: 'Hóa đơn (${_cartItems.length})', icon: const Icon(Icons.shopping_cart)),
                        ],
                      ),
                    ),
                    body: TabBarView(
                      children: [
                        PosCatalogView(
                          products: _products,
                          onVariantSelected: (p, v) {
                            _onAddToCart(p, v);
                            _showSnackbar('Đã thêm ${v.sku} vào hóa đơn');
                          },
                        ),
                        PosRegisterDrawer(
                          cartItems: _cartItems,
                          onItemQuantityChanged: (_) => setState(() {}),
                          onItemRemoved: (item) => setState(() => _cartItems.remove(item)),
                          onClearCart: () => setState(() => _cartItems.clear()),
                          isWalkIn: _isWalkIn,
                          onWalkInChanged: (w) => setState(() => _isWalkIn = w),
                          customers: _customers,
                          selectedCustomer: _selectedCustomer,
                          onCustomerSelected: (c) => setState(() => _selectedCustomer = c),
                          nameController: _nameCtrl,
                          phoneController: _phoneCtrl,
                          subtotal: _subtotal,
                          shippingFee: _shippingFee,
                          paymentMethod: _paymentMethod,
                          onPaymentMethodChanged: (m) => setState(() => _paymentMethod = m),
                          isCounterPickup: _isCounterPickup,
                          onDeliveryPresetChanged: (c) => setState(() {
                            _isCounterPickup = c;
                            _shippingFee = c ? 0.0 : 30000.0;
                          }),
                          onCheckout: _handleCheckout,
                          isSubmitting: _isSubmitting,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
