import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_app/src/data/hardware_mock_data.dart';
import 'package:joppe_app/src/models/cart_item.dart';
import 'package:joppe_app/src/models/order.dart';
import 'package:joppe_app/src/models/product.dart';
import 'package:joppe_app/src/screens/cart_screen.dart';
import 'package:joppe_app/src/screens/checkout_screen.dart';
import 'package:joppe_app/src/screens/order_success_screen.dart';
import 'package:joppe_app/src/services/cart_service.dart';

void main() {
  final sampleProduct1 = HardwareMockData.products[0]; // e.g. Core Ultra 9
  final sampleProduct2 = HardwareMockData.products[1]; // e.g. Core i7

  setUp(() {
    CartService().reset();
  });

  group('CartItem Model Tests', () {
    test('Calculates total price correctly based on quantity', () {
      final item = CartItem(product: sampleProduct1, quantity: 3);
      expect(item.totalPrice, equals(sampleProduct1.price * 3));
      expect(item.formattedTotalPrice, equals(Product.formatVnd(sampleProduct1.price * 3)));
    });

    test('copyWith updates properties properly', () {
      final item = CartItem(product: sampleProduct1, quantity: 1);
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, equals(5));
      expect(updated.product.id, equals(sampleProduct1.id));
    });

    test('Serializes to JSON correctly', () {
      final item = CartItem(product: sampleProduct1, quantity: 2);
      final json = item.toJson();
      expect(json['productId'], equals(sampleProduct1.id));
      expect(json['quantity'], equals(2));
      expect(json['totalPrice'], equals(sampleProduct1.price * 2));
    });
  });

  group('CartService Unit Tests', () {
    test('Starts empty and tracks count and subtotal', () {
      final cart = CartService();
      expect(cart.isEmpty, isTrue);
      expect(cart.totalItemCount, equals(0));
      expect(cart.subtotal, equals(0.0));
    });

    test('addItem adds new item and increments count', () {
      final cart = CartService();
      cart.addItem(sampleProduct1, quantity: 2);

      expect(cart.items.length, equals(1));
      expect(cart.totalItemCount, equals(2));
      expect(cart.subtotal, equals(sampleProduct1.price * 2));

      // Adding the same product increases quantity
      cart.addItem(sampleProduct1, quantity: 1);
      expect(cart.items.length, equals(1));
      expect(cart.totalItemCount, equals(3));
    });

    test('addMultipleProducts adds multiple items from PC Builder', () {
      final cart = CartService();
      cart.addMultipleProducts([sampleProduct1, sampleProduct2]);

      expect(cart.items.length, equals(2));
      expect(cart.totalItemCount, equals(2));
      expect(cart.subtotal, equals(sampleProduct1.price + sampleProduct2.price));
    });

    test('updateQuantity modifies quantity or removes item if <= 0', () {
      final cart = CartService();
      cart.addItem(sampleProduct1, quantity: 2);

      cart.updateQuantity(sampleProduct1.id, 5);
      expect(cart.items.first.quantity, equals(5));

      // Update to 0 removes it
      cart.updateQuantity(sampleProduct1.id, 0);
      expect(cart.isEmpty, isTrue);
    });

    test('removeItem removes product completely', () {
      final cart = CartService();
      cart.addItem(sampleProduct1);
      cart.addItem(sampleProduct2);

      cart.removeItem(sampleProduct1.id);
      expect(cart.items.length, equals(1));
      expect(cart.items.first.product.id, equals(sampleProduct2.id));
    });

    test('clearCart empties the cart', () {
      final cart = CartService();
      cart.addItem(sampleProduct1);
      cart.addItem(sampleProduct2);

      cart.clearCart();
      expect(cart.isEmpty, isTrue);
      expect(cart.totalItemCount, equals(0));
    });

    test('addItem correctly stores variantId from product and preserves local state', () {
      final cart = CartService();
      final productWithVariant = sampleProduct1.copyWith(variantId: 'var-uuid-999');
      cart.addItem(productWithVariant, quantity: 2);

      expect(cart.items.length, equals(1));
      expect(cart.items.first.variantId, equals('var-uuid-999'));
      expect(cart.items.first.quantity, equals(2));
    });

    test('syncWithServer does not wipe local cart items if server is empty', () async {
      final cart = CartService();
      cart.addItem(sampleProduct1, quantity: 1);
      expect(cart.items.length, equals(1));

      // Synchronize with server should preserve local items
      await cart.syncWithServer();
      expect(cart.items.length, equals(1));
      expect(cart.items.first.product.id, equals(sampleProduct1.id));
    });
  });

  group('Order & Shipping / Payment Models Tests', () {
    test('ShippingMethod calculates fees correctly based on subtotal threshold', () {
      const under2M = 1500000.0;
      const over2M = 2500000.0;

      expect(ShippingMethod.standard.calculateFee(under2M), equals(30000.0));
      expect(ShippingMethod.standard.calculateFee(over2M), equals(0.0));
      expect(ShippingMethod.express.calculateFee(over2M), equals(60000.0));
      expect(ShippingMethod.storePickup.calculateFee(under2M), equals(0.0));
    });

    test('PaymentMethodType provides expected title and properties', () {
      expect(PaymentMethodType.vietQr.badgeText, isNotNull);
      expect(PaymentMethodType.cod.title, contains('COD'));
      expect(PaymentMethodType.installment.title, contains('0%'));
    });

    test('Order serializes to JSON correctly', () {
      final order = Order(
        orderId: 'JP-99999',
        items: [CartItem(product: sampleProduct1, quantity: 1)],
        customerName: 'Gamer Pro',
        phoneNumber: '0988776655',
        email: 'gamer@joppe.vn',
        shippingAddress: '172 Thái Hà, Đống Đa, Hà Nội',
        shippingMethod: ShippingMethod.standard,
        paymentMethod: PaymentMethodType.vietQr,
        subtotal: sampleProduct1.price,
        shippingFee: 0.0,
        grandTotal: sampleProduct1.price,
      );

      final json = order.toJson();
      expect(json['orderId'], equals('JP-99999'));
      expect(json['customerName'], equals('Gamer Pro'));
      expect(json['shippingMethod'], equals('standard'));
      expect(json['paymentMethod'], equals('vietQr'));
    });
  });

  group('CheckoutScreen Widget Tests', () {
    testWidgets('Renders empty state when cart has no items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CheckoutScreen(checkoutItems: []),
        ),
      );

      expect(find.text('KHÔNG CÓ SẢN PHẨM CẦN THANH TOÁN'), findsOneWidget);
      expect(find.text('KHÁM PHÁ SẢN PHẨM'), findsOneWidget);
    });

    testWidgets('Renders checkout form with recipient, shipping, payment methods, and summary', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final items = [
        CartItem(product: sampleProduct1, quantity: 1),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(checkoutItems: items),
        ),
      );

      // Verify Header
      expect(find.text('THANH TOÁN'), findsWidgets);
      expect(find.text('SSL 256-BIT'), findsOneWidget);

      // Verify Progress Bar
      expect(find.text('2. THANH TOÁN'), findsOneWidget);

      // Verify Customer Section
      expect(find.text('THÔNG TIN NGƯỜI NHẬN'), findsOneWidget);
      expect(find.text('Họ và tên *'), findsOneWidget);
      expect(find.text('Số điện thoại *'), findsOneWidget);

      // Verify Shipping Section
      expect(find.text('HÌNH THỨC NHẬN HÀNG & ĐỊA CHỈ'), findsOneWidget);
      expect(find.text('GIAO TẬN NƠI'), findsOneWidget);
      expect(find.text('TẠI SHOWROOM'), findsOneWidget);

      // Verify Payment Methods
      expect(find.text('PHƯƠNG THỨC THANH TOÁN'), findsOneWidget);
      expect(find.text('Chuyển khoản QR (VietQR / Napas 247)'), findsOneWidget);
      expect(find.text('Thanh toán khi nhận hàng (COD)'), findsOneWidget);

      // Verify Order Items
      expect(find.text(sampleProduct1.name), findsOneWidget);

      // Verify Submit Button
      expect(find.text('XÁC NHẬN THANH TOÁN'), findsOneWidget);
    });

    testWidgets('Applies discount voucher JOPPE2026 successfully', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final items = [CartItem(product: sampleProduct1, quantity: 1)];

      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(checkoutItems: items),
        ),
      );

      // Enter Voucher Code
      final voucherFinder = find.widgetWithText(TextField, 'Nhập mã (VD: JOPPE2026, AI100, FREESHIP)...');
      expect(voucherFinder, findsOneWidget);

      await tester.enterText(voucherFinder, 'JOPPE2026');
      await tester.tap(find.text('ÁP DỤNG'));
      await tester.pump();

      // Verify Success message
      expect(find.text('Áp dụng mã JOPPE2026 thành công: Giảm 500.000 ₫!'), findsOneWidget);
      expect(find.text('Giảm giá mã (JOPPE2026):'), findsOneWidget);
      expect(find.text('-500.000 ₫'), findsOneWidget);
    });

    testWidgets('Shows validation errors if required fields are missing upon submit', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final items = [CartItem(product: sampleProduct1, quantity: 1)];

      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(checkoutItems: items),
        ),
      );

      // Tap submit without entering required name, phone, address
      final submitButton = find.text('XÁC NHẬN THANH TOÁN');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Bắt buộc nhập họ tên'), findsOneWidget);
      expect(find.text('Bắt buộc'), findsOneWidget);
      expect(find.text('Bắt buộc nhập địa chỉ giao hàng'), findsOneWidget);
    });

    testWidgets('Renders without RenderFlex overflow on small 360x640 mobile screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final items = [
        CartItem(
          product: sampleProduct1,
          quantity: 3,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CheckoutScreen(checkoutItems: items),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('THANH TOÁN'), findsWidgets);
      expect(find.text('GIAO TẬN NƠI'), findsOneWidget);
      expect(find.text('TẠI SHOWROOM'), findsOneWidget);
      expect(find.text('KHUYÊN DÙNG'), findsOneWidget);
    });
  });

  group('OrderSuccessScreen Widget Tests', () {
    testWidgets('Renders VietQR and bank transfer card for VietQR orders', (WidgetTester tester) async {
      final order = Order(
        orderId: 'JP-2026-TEST',
        items: [CartItem(product: sampleProduct1, quantity: 1)],
        customerName: 'Nguyễn Văn A',
        phoneNumber: '0912345678',
        email: 'test@joppe.vn',
        shippingAddress: '172 Thái Hà, Hà Nội',
        shippingMethod: ShippingMethod.standard,
        paymentMethod: PaymentMethodType.vietQr,
        subtotal: 10000000,
        shippingFee: 0,
        grandTotal: 10000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrderSuccessScreen(order: order),
        ),
      );

      expect(find.text('ĐẶT HÀNG THÀNH CÔNG!'), findsOneWidget);
      expect(find.text('JP-2026-TEST'), findsWidgets);
      expect(find.text('QUÉT MÃ VIETQR ĐỂ HOÀN TẤT THANH TOÁN'), findsOneWidget);
      expect(find.text('0868302123'), findsWidgets);
      expect(find.text('MB Bank (Quân Đội)'), findsOneWidget);
      expect(find.text('SAO CHÉP MÃ ĐƠN'), findsOneWidget);
      expect(find.text('TIẾP TỤC MUA SẮM'), findsOneWidget);
    });

    testWidgets('Renders VNPay payment card with gateway portal URL and official badge', (WidgetTester tester) async {
      final order = Order(
        orderId: 'JP-2026-VNPAY',
        items: [CartItem(product: sampleProduct1, quantity: 1)],
        customerName: 'Nguyễn Văn B',
        phoneNumber: '0987654321',
        email: 'vnpay@joppe.vn',
        shippingAddress: 'Showroom Joppe',
        shippingMethod: ShippingMethod.storePickup,
        paymentMethod: PaymentMethodType.vnpay,
        subtotal: 15000000,
        shippingFee: 0,
        grandTotal: 15000000,
        vnpayPaymentUrl: 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Amount=1500000000&vnp_SecureHash=mockhash123',
        vnpayTxnRef: 'JP-2026-VNPAY_123456',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrderSuccessScreen(order: order),
        ),
      );

      expect(find.text('THANH TOÁN QUA CỔNG VNPAY & MÃ VNPAY-QR'), findsOneWidget);
      expect(find.text('CHÍNH THỨC'), findsOneWidget);
      expect(find.text('MỞ CỔNG THANH TOÁN VNPAY'), findsOneWidget);
      expect(find.text('Sao chép liên kết thanh toán'), findsOneWidget);
      expect(find.text('JP-2026-VNPAY_123456'), findsOneWidget);
      // Ensures the buggy URL is NEVER shown
      expect(find.text('https://joppe.penguinlab.org/orders/JP-2026-VNPAY'), findsNothing);
    });
  });

  group('CartScreen Integration Tests', () {
    testWidgets('Displays empty cart state when cart is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CartScreen(),
        ),
      );

      expect(find.text('GIỎ HÀNG ĐANG TRỐNG'), findsOneWidget);
      expect(find.text('TIẾP TỤC MUA SẮM'), findsOneWidget);
    });

    testWidgets('Displays products and checkout button when cart has items', (WidgetTester tester) async {
      CartService().addItem(sampleProduct1, quantity: 2);

      await tester.pumpWidget(
        const MaterialApp(
          home: CartScreen(),
        ),
      );

      expect(find.text(sampleProduct1.name), findsOneWidget);
      expect(find.text('TIẾN HÀNH THANH TOÁN'), findsOneWidget);
      expect(find.text('2'), findsWidgets);
    });
  });
}
