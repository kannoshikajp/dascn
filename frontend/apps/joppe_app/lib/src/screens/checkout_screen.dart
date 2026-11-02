import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/vnpay_payment.dart';
import '../services/app_api_client.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/store_domain_api_service.dart';
import '../widgets/common/product_image.dart';
import 'order_success_screen.dart';

/// Màn hình thanh toán hoàn chỉnh theo phong cách góc vuông Boxy Flat 90 độ cho Joppe E-Commerce
class CheckoutScreen extends StatefulWidget {
  final List<CartItem>? checkoutItems;

  const CheckoutScreen({super.key, this.checkoutItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // Thông tin người nhận
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  // Thẻ tín dụng mô phỏng
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  // Hóa đơn VAT
  final _companyNameController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _companyAddressController = TextEditingController();

  // Voucher
  final _voucherController = TextEditingController();
  String? _appliedVoucherCode;
  double _voucherDiscountAmount = 0.0;
  String? _voucherMessage;
  bool _isVoucherValid = false;

  // Lựa chọn vận chuyển & thanh toán
  bool _isDelivery = true; // true = Giao hàng tận nơi, false = Nhận tại Showroom
  String _selectedCity = 'Hà Nội';
  int _selectedShowroomIndex = 0;
  ShippingMethod _shippingMethod = ShippingMethod.standard;
  PaymentMethodType _selectedPaymentMethod = PaymentMethodType.vietQr;
  int _installmentMonths = 6;

  bool _isVatRequested = false;
  bool _usePoints = false;
  bool _agreedToTerms = true;
  bool _isSubmitting = false;

  final List<String> _vietnamCities = [
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Đà Nẵng',
    'Hải Phòng',
    'Cần Thơ',
    'Bình Dương',
    'Đồng Nai',
    'Khánh Hòa',
    'Quảng Ninh',
    'Tỉnh / Thành khác',
  ];

  final List<Map<String, String>> _showrooms = [
    {
      'name': 'Showroom Hà Nội',
      'address': '172 Thái Hà, P. Trung Liệt, Q. Đống Đa, Hà Nội',
      'hotline': '086 830 2123',
    },
    {
      'name': 'Showroom TP. Hồ Chí Minh',
      'address': '84 Cao Thắng, Phường 4, Quận 3, TP. Hồ Chí Minh',
      'hotline': '086 830 2124',
    },
    {
      'name': 'Showroom Đà Nẵng',
      'address': '152 Hàm Nghi, P. Thạc Gián, Q. Thanh Khê, Đà Nẵng',
      'hotline': '086 830 2125',
    },
  ];

  List<Map<String, dynamic>> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    final currentUser = AuthService().currentUser;

    _nameController = TextEditingController(text: currentUser?.fullName ?? '');
    _phoneController = TextEditingController(text: currentUser?.phoneNumber ?? '');
    _emailController = TextEditingController(text: currentUser?.email ?? '');
    _addressController = TextEditingController();
    _notesController = TextEditingController();

    _loadSavedAddresses();
  }

  void _loadSavedAddresses() async {
    if (!AuthService().isAuthenticated) return;
    try {
      final res = await StoreDomainApiService().listAddresses();
      if (res.isSuccess && res.data is List && mounted) {
        setState(() {
          _savedAddresses = (res.data as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
          if (_savedAddresses.isNotEmpty && _addressController.text.isEmpty) {
            final defaultAddr = _savedAddresses.firstWhere(
              (a) => a['isDefault'] == true,
              orElse: () => _savedAddresses.first,
            );
            _addressController.text = defaultAddr['streetAddress']?.toString() ?? '';
            if (defaultAddr['recipientName'] != null && _nameController.text.isEmpty) {
              _nameController.text = defaultAddr['recipientName'].toString();
            }
            if (defaultAddr['recipientPhone'] != null && _phoneController.text.isEmpty) {
              _phoneController.text = defaultAddr['recipientPhone'].toString();
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _companyNameController.dispose();
    _taxCodeController.dispose();
    _companyAddressController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  List<CartItem> get _items {
    if (widget.checkoutItems != null && widget.checkoutItems!.isNotEmpty) {
      return widget.checkoutItems!;
    }
    return CartService().items;
  }

  double get _subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get _shippingFee {
    if (!_isDelivery) return 0.0;
    if (_appliedVoucherCode == 'FREESHIP') return 0.0;
    return _shippingMethod.calculateFee(_subtotal);
  }

  double get _pointsDiscount {
    if (!_usePoints) return 0.0;
    final user = AuthService().currentUser;
    if (user == null || user.rewardPoints <= 0) return 0.0;
    // 1 điểm = 1.000 ₫, tối đa giảm không quá 20% đơn hàng hoặc số điểm hiện có
    final maxAllowedDiscount = _subtotal * 0.20;
    final pointsWorth = user.rewardPoints * 1000.0;
    return min(maxAllowedDiscount, pointsWorth);
  }

  double get _grandTotal {
    final rawTotal = _subtotal + _shippingFee - _voucherDiscountAmount - _pointsDiscount;
    return max(0.0, rawTotal);
  }

  void _applyVoucher() {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _appliedVoucherCode = null;
        _voucherDiscountAmount = 0.0;
        _voucherMessage = null;
        _isVoucherValid = false;
      });
      return;
    }

    if (code == 'JOPPE2026') {
      setState(() {
        _appliedVoucherCode = code;
        _voucherDiscountAmount = 500000.0;
        _voucherMessage = 'Áp dụng mã JOPPE2026 thành công: Giảm 500.000 ₫!';
        _isVoucherValid = true;
      });
    } else if (code == 'AI100') {
      setState(() {
        _appliedVoucherCode = code;
        _voucherDiscountAmount = _subtotal * 0.10;
        _voucherMessage = 'Áp dụng mã AI100 thành công: Giảm 10% đơn hàng!';
        _isVoucherValid = true;
      });
    } else if (code == 'FREESHIP') {
      setState(() {
        _appliedVoucherCode = code;
        _voucherDiscountAmount = 0.0; // Miễn phí vận chuyển được tính ở _shippingFee
        _voucherMessage = 'Áp dụng mã FREESHIP thành công: Miễn phí giao hàng toàn quốc!';
        _isVoucherValid = true;
      });
    } else if (code == 'GAMING') {
      setState(() {
        _appliedVoucherCode = code;
        _voucherDiscountAmount = 200000.0;
        _voucherMessage = 'Áp dụng mã GAMING thành công: Giảm 200.000 ₫!';
        _isVoucherValid = true;
      });
    } else {
      setState(() {
        _appliedVoucherCode = null;
        _voucherDiscountAmount = 0.0;
        _voucherMessage = 'Mã giảm giá không hợp lệ hoặc đã hết hạn!';
        _isVoucherValid = false;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng kiểm tra lại thông tin nhận hàng còn thiếu!'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với điều khoản mua hàng và bảo hành của JOPPE!'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String orderId = 'JP-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final fullAddress = _isDelivery
        ? '${_addressController.text.trim()}, $_selectedCity'
        : _showrooms[_selectedShowroomIndex]['address']!;

    final pointsUsed = _usePoints
        ? min(AuthService().currentUser?.rewardPoints ?? 0, (_pointsDiscount / 1000).round())
        : 0;

    String? vnpayPaymentUrl;
    String? vnpayQrCodeUrl;
    String? vnpayPaymentId;
    String? vnpayTxnRef;
    String? vnpayQrCodeBase64;

    // Đấu nối gửi đơn hàng lên máy chủ API Joppe theo API_SCHEMA.md mục 11.1
    try {
      final itemsPayload = _items
          .map((it) => {
                'variantId': it.variantId ?? it.product.variantId ?? it.product.id,
                'quantity': it.quantity,
              })
          .toList();

      final apiResponse = await StoreDomainApiService().checkoutOrder(
        recipientName: _nameController.text.trim(),
        recipientPhone: _phoneController.text.trim(),
        shippingAddress: fullAddress,
        customerNote: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        shippingFee: _shippingFee,
        items: itemsPayload,
      );

      if (apiResponse.isSuccess && apiResponse.data is Map) {
        final serverCode = apiResponse.data['orderCode'] ?? apiResponse.data['id'] ?? apiResponse.data['orderId'];
        if (serverCode != null && serverCode.toString().isNotEmpty) {
          orderId = serverCode.toString();
        }
        final realOrderId = apiResponse.data['id']?.toString() ?? orderId;

        // Nếu phương thức thanh toán là VNPAY hoặc Chuyển khoản QR: Khởi tạo liên kết thanh toán qua API
        if (_selectedPaymentMethod == PaymentMethodType.vnpay || _selectedPaymentMethod == PaymentMethodType.vietQr) {
          try {
            final vnpayRes = await StoreDomainApiService().createVnPayPayment(
              orderId: realOrderId,
              orderCode: orderId,
              amount: _grandTotal,
              returnUrl: 'https://joppe.penguinlab.org/checkout/callback',
            );
            if (vnpayRes.isSuccess && vnpayRes.data is Map) {
              final vnpayData = VnPayPaymentResponse.fromJson(Map<String, dynamic>.from(vnpayRes.data));
              vnpayPaymentUrl = vnpayData.paymentUrl;
              vnpayQrCodeUrl = vnpayData.getFullQrUrl(AppApiClient.instance.baseUrl);
              vnpayPaymentId = vnpayData.paymentId;
              vnpayTxnRef = vnpayData.txnRef;
              vnpayQrCodeBase64 = vnpayData.qrCodeBase64;
            }
          } catch (_) {
            // Dự phòng không ngắt mạch luồng đặt hàng
          }
        }
      }
    } catch (_) {
      // Fallback cục bộ an toàn nếu mạng chập chờn
    }

    // Đảm bảo đơn VNPAY luôn có liên kết thanh toán cổng VNPAY (chính thức hoặc sandbox fallback)
    if (_selectedPaymentMethod == PaymentMethodType.vnpay && (vnpayPaymentUrl == null || vnpayPaymentUrl.isEmpty)) {
      try {
        final vnpayRes = await StoreDomainApiService().createVnPayPayment(
          orderId: orderId,
          orderCode: orderId,
          amount: _grandTotal,
          returnUrl: 'https://joppe.penguinlab.org/checkout/callback',
        );
        if (vnpayRes.isSuccess && vnpayRes.data is Map) {
          final vnpayData = VnPayPaymentResponse.fromJson(Map<String, dynamic>.from(vnpayRes.data));
          vnpayPaymentUrl = vnpayData.paymentUrl;
          vnpayQrCodeUrl = vnpayData.getFullQrUrl(AppApiClient.instance.baseUrl);
          vnpayPaymentId = vnpayData.paymentId;
          vnpayTxnRef = vnpayData.txnRef;
          vnpayQrCodeBase64 = vnpayData.qrCodeBase64;
        }
      } catch (_) {}
    }

    final createdOrder = Order(
      orderId: orderId,
      items: List.from(_items),
      customerName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      shippingAddress: fullAddress,
      shippingMethod: _isDelivery ? _shippingMethod : ShippingMethod.storePickup,
      paymentMethod: _selectedPaymentMethod,
      orderNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      subtotal: _subtotal,
      shippingFee: _shippingFee,
      voucherCode: _appliedVoucherCode,
      discountAmount: _voucherDiscountAmount,
      pointsUsed: pointsUsed,
      pointsDiscount: _pointsDiscount,
      grandTotal: _grandTotal,
      isVatRequested: _isVatRequested,
      companyName: _isVatRequested ? _companyNameController.text.trim() : null,
      taxCode: _isVatRequested ? _taxCodeController.text.trim() : null,
      companyAddress: _isVatRequested ? _companyAddressController.text.trim() : null,
      vnpayPaymentUrl: vnpayPaymentUrl,
      vnpayQrCodeUrl: vnpayQrCodeUrl,
      vnpayPaymentId: vnpayPaymentId,
      vnpayTxnRef: vnpayTxnRef,
      vnpayQrCodeBase64: vnpayQrCodeBase64,
    );

    // Nếu thanh toán toàn bộ giỏ hàng chính, xóa sạch giỏ
    if (widget.checkoutItems == null || widget.checkoutItems!.isEmpty) {
      CartService().clearCart();
    }

    if (!mounted) return;

    // Điều hướng sang màn hình thành công
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSuccessScreen(order: createdOrder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        titleSpacing: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
        title: InkWell(
          onTap: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: AppColors.surfaceCard,
                child: const Text(
                  'JOPPE',
                  style: TextStyle(
                    color: AppColors.neonCyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'THANH TOÁN',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, color: AppColors.neonCyan, size: 13),
                SizedBox(width: 3),
                Text(
                  'SSL 256-BIT',
                  style: TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Trang chủ JOPPE',
            icon: const Icon(Icons.home_outlined, color: AppColors.neonCyan),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh tiến trình Step 2
              _buildStepIndicator(),
              const SizedBox(height: 16),

              // Card 1: Thông tin người nhận
              _buildCustomerInfoCard(),
              const SizedBox(height: 16),

              // Card 2: Hình thức giao nhận & Địa chỉ
              _buildShippingMethodCard(),
              const SizedBox(height: 16),

              // Card 3: Phương thức thanh toán
              _buildPaymentMethodsCard(),
              const SizedBox(height: 16),

              // Card 4: Xuất hóa đơn VAT
              _buildVatInvoiceCard(),
              const SizedBox(height: 16),

              // Card 5: Tóm tắt đơn hàng & Danh sách sản phẩm
              _buildOrderItemsCard(),
              const SizedBox(height: 16),

              // Card 6: Mã giảm giá & Điểm thưởng
              _buildVoucherAndPointsCard(),
              const SizedBox(height: 16),

              // Card 7: Bảng tính tiền & Nút xác nhận thanh toán
              _buildGrandTotalCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text('THANH TOÁN', style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border.all(color: AppColors.borderLight, width: 2),
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 36, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              const Text(
                'KHÔNG CÓ SẢN PHẨM CẦN THANH TOÁN',
                style: TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng chọn linh kiện hoặc thiết bị trước khi tiến hành thanh toán.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.textOnAction,
                  shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('KHÁM PHÁ SẢN PHẨM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Row(
        children: [
          _buildStepItem('1. GIỎ HÀNG', isCompleted: true),
          const Icon(Icons.arrow_right_alt, color: AppColors.neonCyan, size: 16),
          _buildStepItem('2. THANH TOÁN', isActive: true),
          const Icon(Icons.arrow_right_alt, color: AppColors.borderLight, size: 16),
          _buildStepItem('3. HOÀN TẤT', isCompleted: false),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, {bool isActive = false, bool isCompleted = false}) {
    return Expanded(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isActive
              ? AppColors.neonCyan
              : (isCompleted ? AppColors.textWhite : AppColors.textSubtle),
          fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
          fontSize: 10,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.primaryDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: AppColors.neonCyan, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    final user = AuthService().currentUser;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            icon: Icons.person_outline,
            title: 'THÔNG TIN NGƯỜI NHẬN',
            trailing: user != null
                ? InkWell(
                    onTap: () {
                      setState(() {
                        _nameController.text = user.fullName;
                        _phoneController.text = user.phoneNumber;
                        _emailController.text = user.email;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã đồng bộ thông tin tài khoản JOPPE thành công!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text(
                      'DÙNG THÔNG TIN TÀI KHOẢN',
                      style: TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildSquareInputField(
                        controller: _nameController,
                        label: 'Họ và tên *',
                        hint: 'Nguyễn Văn A',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập họ tên' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildSquareInputField(
                        controller: _phoneController,
                        label: 'Số điện thoại *',
                        hint: '09xxxxxxxx',
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                          if (v.trim().length < 9) return 'SĐT không đúng';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSquareInputField(
                  controller: _emailController,
                  label: 'Email nhận hóa đơn điện tử & bảo hành *',
                  hint: 'email@domain.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Bắt buộc nhập email';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            icon: Icons.local_shipping_outlined,
            title: 'HÌNH THỨC NHẬN HÀNG & ĐỊA CHỈ',
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Chọn Giao hàng hoặc Nhận tại Showroom (Segmented Square Bar)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isDelivery = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isDelivery ? AppColors.primaryBlue : AppColors.surfaceCardLighter,
                            border: Border.all(
                              color: _isDelivery ? AppColors.neonCyan : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delivery_dining,
                                color: _isDelivery ? AppColors.textOnAction : AppColors.textMuted,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'GIAO TẬN NƠI',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _isDelivery ? AppColors.textOnAction : AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isDelivery = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isDelivery ? AppColors.primaryBlue : AppColors.surfaceCardLighter,
                            border: Border.all(
                              color: !_isDelivery ? AppColors.neonCyan : AppColors.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.storefront,
                                color: !_isDelivery ? AppColors.textOnAction : AppColors.textMuted,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'TẠI SHOWROOM',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: !_isDelivery ? AppColors.textOnAction : AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_isDelivery) ...[
                  // Giao hàng tận nơi
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCity,
                          dropdownColor: AppColors.surfaceCard,
                          style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Tỉnh / Thành phố *',
                            labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            filled: true,
                            fillColor: AppColors.searchFieldBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: _vietnamCities.map((city) {
                            return DropdownMenuItem(value: city, child: Text(city));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCity = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSquareInputField(
                    controller: _addressController,
                    label: 'Địa chỉ nhận hàng chi tiết *',
                    hint: 'Số nhà, ngõ/ngách, tên đường, phường/xã, quận/huyện',
                    validator: (v) {
                      if (_isDelivery && (v == null || v.trim().isEmpty)) {
                        return 'Bắt buộc nhập địa chỉ giao hàng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Lựa chọn tốc độ giao hàng
                  const Text(
                    'DỊCH VỤ VẬN CHUYỂN:',
                    style: TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildShippingOption(
                    method: ShippingMethod.standard,
                    feeText: _subtotal >= 2000000 ? 'MIỄN PHÍ' : '30.000 ₫',
                  ),
                  const SizedBox(height: 8),
                  _buildShippingOption(
                    method: ShippingMethod.express,
                    feeText: '60.000 ₫',
                  ),
                ] else ...[
                  // Nhận tại Showroom
                  const Text(
                    'CHỌN SHOWROOM NHẬN HÀNG:',
                    style: TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_showrooms.length, (idx) {
                    final sr = _showrooms[idx];
                    final isSelected = _selectedShowroomIndex == idx;
                    return InkWell(
                      onTap: () => setState(() => _selectedShowroomIndex = idx),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.15) : AppColors.primaryDark,
                          border: Border.all(
                            color: isSelected ? AppColors.neonCyan : AppColors.borderLight,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? AppColors.neonCyan : AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sr['name']!,
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${sr['address']}\nHotline: ${sr['hotline']}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 12),
                _buildSquareInputField(
                  controller: _notesController,
                  label: 'Ghi chú đơn hàng (Tùy chọn)',
                  hint: 'Ví dụ: Giao vào giờ hành chính, gọi trước 15 phút, hỗ trợ lắp linh kiện...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingOption({required ShippingMethod method, required String feeText}) {
    final isSelected = _shippingMethod == method;
    return InkWell(
      onTap: () => setState(() => _shippingMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.15) : AppColors.primaryDark,
          border: Border.all(
            color: isSelected ? AppColors.neonCyan : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.neonCyan : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    method.description,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: feeText == 'MIỄN PHÍ' ? Colors.green.shade900 : AppColors.primaryDark,
              child: Text(
                feeText,
                style: TextStyle(
                  color: feeText == 'MIỄN PHÍ' ? Colors.greenAccent : AppColors.neonCyan,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            icon: Icons.payment,
            title: 'PHƯƠNG THỨC THANH TOÁN',
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildPaymentTile(
                  type: PaymentMethodType.vietQr,
                  icon: Icons.qr_code_scanner,
                ),
                const SizedBox(height: 8),
                _buildPaymentTile(
                  type: PaymentMethodType.cod,
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 8),
                _buildPaymentTile(
                  type: PaymentMethodType.momo,
                  icon: Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 8),
                _buildPaymentTile(
                  type: PaymentMethodType.vnpay,
                  icon: Icons.account_balance,
                ),
                const SizedBox(height: 8),
                _buildPaymentTile(
                  type: PaymentMethodType.creditCard,
                  icon: Icons.credit_card,
                ),
                if (_selectedPaymentMethod == PaymentMethodType.creditCard) ...[
                  const SizedBox(height: 10),
                  _buildCreditCardForm(),
                ],
                const SizedBox(height: 8),
                _buildPaymentTile(
                  type: PaymentMethodType.installment,
                  icon: Icons.calendar_month,
                ),
                if (_selectedPaymentMethod == PaymentMethodType.installment) ...[
                  const SizedBox(height: 10),
                  _buildInstallmentForm(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile({required PaymentMethodType type, required IconData icon}) {
    final isSelected = _selectedPaymentMethod == type;
    final badge = type.badgeText;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.15) : AppColors.primaryDark,
          border: Border.all(
            color: isSelected ? AppColors.neonCyan : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.neonCyan : AppColors.textMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Icon(icon, color: isSelected ? AppColors.neonCyan : AppColors.textWhite, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        type.title,
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          color: AppColors.accentRed,
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.subtitle,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.searchFieldBg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN THẺ QUỐC TẾ (MÔ PHỎNG BẢO MẬT):',
            style: TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildSquareInputField(
            controller: _cardNumberController,
            label: 'Số thẻ (16 chữ số)',
            hint: '4111 2222 3333 4444',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildSquareInputField(
                  controller: _cardHolderController,
                  label: 'Tên in trên thẻ',
                  hint: 'NGUYEN VAN A',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSquareInputField(
                  controller: _cardExpiryController,
                  label: 'Hạn (MM/YY)',
                  hint: '12/28',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSquareInputField(
                  controller: _cardCvvController,
                  label: 'CVV',
                  hint: '123',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentForm() {
    final monthlyPrice = _grandTotal / _installmentMonths;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.searchFieldBg,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHỌN KỲ HẠN TRẢ GÓP 0%:',
            style: TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [3, 6, 9, 12].map((months) {
              final isSel = _installmentMonths == months;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSel ? AppColors.primaryBlue : AppColors.surfaceCardLighter,
                      foregroundColor: isSel ? AppColors.textOnAction : AppColors.textPrimary,
                      side: BorderSide(color: isSel ? AppColors.neonCyan : AppColors.borderLight),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => setState(() => _installmentMonths = months),
                    child: Text('$months Tháng', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            color: AppColors.surfaceCardLighter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số tiền thanh toán mỗi tháng ($_installmentMonths tháng):',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                Text(
                  Product.formatVnd(monthlyPrice),
                  style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVatInvoiceCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: _isVatRequested,
              activeColor: AppColors.primaryBlue,
              checkColor: AppColors.textOnAction,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              title: const Text(
                'YÊU CẦU XUẤT HÓA ĐƠN ĐỎ (VAT ĐIỆN TỬ)',
                style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w900, fontSize: 12),
              ),
              subtitle: const Text(
                'Hóa đơn điện tử hợp lệ gửi qua email doanh nghiệp trong 24h',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              onChanged: (val) => setState(() => _isVatRequested = val ?? false),
            ),
          ),
          if (_isVatRequested) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  _buildSquareInputField(
                    controller: _companyNameController,
                    label: 'Tên công ty / Doanh nghiệp *',
                    hint: 'Công ty TNHH Giải Pháp Công Nghệ...',
                    validator: (v) => (_isVatRequested && (v == null || v.trim().isEmpty)) ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSquareInputField(
                          controller: _taxCodeController,
                          label: 'Mã số thuế (MST) *',
                          hint: '0101234567',
                          keyboardType: TextInputType.number,
                          validator: (v) => (_isVatRequested && (v == null || v.trim().isEmpty)) ? 'Bắt buộc' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: _buildSquareInputField(
                          controller: _companyAddressController,
                          label: 'Địa chỉ đăng ký kinh doanh *',
                          hint: 'Số ... Đường ..., TP. ...',
                          validator: (v) => (_isVatRequested && (v == null || v.trim().isEmpty)) ? 'Bắt buộc' : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            icon: Icons.list_alt,
            title: 'DANH SÁCH SẢN PHẨM (${_items.length} MÓN)',
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: _items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(8),
                  color: AppColors.primaryDark,
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: ProductImage(
                          imageUrl: item.product.imageUrl,
                          componentType: item.product.componentType,
                          brand: item.product.brand,
                          width: 52,
                          height: 52,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Đơn giá: ${item.product.formattedPrice} | SL: x${item.quantity}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.formattedTotalPrice,
                        style: const TextStyle(
                          color: AppColors.neonCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherAndPointsCard() {
    final user = AuthService().currentUser;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            icon: Icons.card_giftcard,
            title: 'MÃ KHUYẾN MÃI & ĐIỂM THƯỞNG',
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input mã giảm giá
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _voucherController,
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'Nhập mã (VD: JOPPE2026, AI100, FREESHIP)...',
                          hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.searchFieldBg,
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                            borderSide: BorderSide(color: AppColors.borderLight),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                            borderSide: BorderSide(color: AppColors.borderLight),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                            borderSide: BorderSide(color: AppColors.neonCyan),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.textOnAction,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: _applyVoucher,
                      child: const Text('ÁP DỤNG', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ],
                ),
                if (_voucherMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _voucherMessage!,
                    style: TextStyle(
                      color: _isVoucherValid ? Colors.greenAccent : AppColors.accentRed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                // Điểm thưởng JOPPE Rewards
                if (user != null && user.rewardPoints > 0) ...[
                  const Divider(color: AppColors.borderLight, height: 24),
                  Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      value: _usePoints,
                      activeColor: AppColors.primaryBlue,
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'DÙNG ĐIỂM JOPPE (${user.rewardPoints} ĐIỂM KHẢ DỤNG)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Quy đổi giảm tối đa ${Product.formatVnd(_pointsDiscount > 0 ? _pointsDiscount : (user.rewardPoints * 1000.0))} cho đơn hàng này',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      onChanged: (val) => setState(() => _usePoints = val ?? false),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.primaryBlue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'CHI TIẾT THANH TOÁN',
            style: TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildCalculationRow('Tạm tính:', Product.formatVnd(_subtotal)),
          _buildCalculationRow(
            'Phí vận chuyển:',
            _shippingFee == 0 ? 'MIỄN PHÍ' : Product.formatVnd(_shippingFee),
            isGreen: _shippingFee == 0,
          ),
          if (_voucherDiscountAmount > 0)
            _buildCalculationRow(
              'Giảm giá mã ($_appliedVoucherCode):',
              '-${Product.formatVnd(_voucherDiscountAmount)}',
              isGreen: true,
            ),
          if (_pointsDiscount > 0)
            _buildCalculationRow(
              'Giảm điểm thưởng:',
              '-${Product.formatVnd(_pointsDiscount)}',
              isGreen: true,
            ),
          const Divider(color: AppColors.borderLight, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TỔNG TIỀN PHẢI TRẢ:',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '(Đã bao gồm VAT & dịch vụ)',
                      style: TextStyle(color: AppColors.textSubtle, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    Product.formatVnd(_grandTotal),
                    style: const TextStyle(
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checkbox điều khoản
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: _agreedToTerms,
              activeColor: AppColors.primaryBlue,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Tôi đã kiểm tra kỹ đơn hàng và đồng ý với Điều khoản mua hàng & Bảo hành của JOPPE.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
            ),
          ),
          const SizedBox(height: 14),

          // Nút Đặt hàng
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textOnAction,
              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(18))),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 4,
            ),
            onPressed: _isSubmitting ? null : _submitOrder,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnAction),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'XÁC NHẬN THANH TOÁN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: isGreen ? Colors.greenAccent : AppColors.textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
            filled: true,
            fillColor: AppColors.searchFieldBg,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: AppColors.neonCyan),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: AppColors.accentRed),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          validator: validator,
        ),
      ],
    );
  }
}
