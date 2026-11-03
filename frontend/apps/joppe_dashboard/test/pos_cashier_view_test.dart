import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/views/pos/pos_cashier_view.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late OrderService orderService;
  late ProductManagementService productService;
  late UserManagementService userService;

  setUp(() {
    bool isOrderPaid = false;

    mockClient = MockClient((request) async {
      if (request.url.path == '/api/v1/admin/products') {
        return http.Response(
          jsonEncode([
            {
              'id': 'prod-1',
              'productName': 'NVIDIA RTX 4080 Super',
              'slug': 'rtx-4080-super',
              'brandId': 1,
              'brandName': 'ASUS',
              'isActive': true,
              'minPrice': 28000000.0,
              'maxPrice': 28000000.0,
              'totalStock': 10,
              'categories': [
                {'id': 1, 'categoryName': 'VGA', 'slug': 'vga', 'isPrimary': true}
              ],
              'variants': [
                {
                  'id': 'var-1',
                  'sku': 'ROG-4080S-16G',
                  'variantName': '16GB GDDR6X',
                  'salePrice': 28000000.0,
                  'listPrice': 30000000.0,
                  'quantityOnHand': 10,
                  'quantityReserved': 0,
                  'isActive': true,
                }
              ],
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/users') {
        return http.Response(
          jsonEncode([
            {
              'id': 'user-1',
              'fullName': 'Nguyen Van A',
              'email': 'customer@joppe.vn',
              'phoneNumber': '0901234567',
              'roleId': 2,
              'roleName': 'ROLE_CUSTOMER',
              'isActive': true,
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/orders' && request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        isOrderPaid = body['paymentStatus'] == 'PAID';
        return http.Response(
          jsonEncode({
            'id': 'new-ord-1',
            'orderCode': 'ORD-POS-20261029-99',
            'recipientName': 'Khách lẻ vãng lai',
            'recipientPhone': '0900000000',
            'finalAmount': 28000000.0,
            'orderStatus': 'DELIVERED',
            'paymentStatus': isOrderPaid ? 'PAID' : 'UNPAID',
            'items': [],
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
      if ((request.url.path == '/api/v1/admin/orders/new-ord-1/payment-status' && request.method == 'PATCH') ||
          (request.url.path == '/api/v1/admin/orders/new-ord-1/manual-payment-confirm' && request.method == 'POST')) {
        isOrderPaid = true;
        return http.Response(
          jsonEncode({
            'id': 'new-ord-1',
            'orderCode': 'ORD-POS-20261029-99',
            'userId': 'user-1',
            'orderStatus': 'DELIVERED',
            'paymentStatus': 'PAID',
            'recipientName': 'Khách lẻ vãng lai',
            'recipientPhone': '0900000000',
            'finalAmount': 28000000.0,
            'items': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/payment/vnpay/create' && request.method == 'POST') {
        return http.Response(
          jsonEncode({
            'paymentId': 'pay-vnpay-1',
            'paymentUrl': 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Amount=2800000000&vnp_TxnRef=ORD-POS-20261029-99',
            'orderCode': 'ORD-POS-20261029-99',
            'txnRef': 'ORD-POS-20261029-99_123',
            'amount': 28000000.0,
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/orders/new-ord-1') {
        return http.Response(
          jsonEncode({
            'id': 'new-ord-1',
            'orderCode': 'ORD-POS-20261029-99',
            'userId': 'user-1',
            'orderStatus': 'DELIVERED',
            'paymentStatus': isOrderPaid ? 'PAID' : 'UNPAID',
            'recipientName': 'Khách lẻ vãng lai',
            'recipientPhone': '0900000000',
            'finalAmount': 28000000.0,
            'items': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });

    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    orderService = OrderService(apiClient);
    productService = ProductManagementService(apiClient);
    userService = UserManagementService(apiClient);
  });

  testWidgets('PosCashierView displays product, adds to cart, and updates total to pay', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: PosCashierView(
            orderService: orderService,
            productService: productService,
            userService: userService,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify product card is displayed in catalog
    expect(find.text('NVIDIA RTX 4080 Super'), findsOneWidget);
    expect(find.text('ROG-4080S-16G'), findsOneWidget);

    // Initial cart is empty (0 món)
    expect(find.text('0 món'), findsOneWidget);
    expect(find.text('Giỏ hàng trống'), findsOneWidget);
    expect(find.text('TỔNG TIỀN PHẢI TRẢ'), findsOneWidget);

    // Tap on add to cart button on product card
    final addIcon = find.byTooltip('Thêm vào đơn');
    expect(addIcon, findsOneWidget);
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // Verify cart now has 1 item and displays total money to pay
    expect(find.text('1 món'), findsOneWidget);
    expect(find.text('28.000.000 ₫'), findsWidgets);

    // Tap on checkout button
    final checkoutButton = find.text('Thanh toán 28.000.000 ₫');
    expect(checkoutButton, findsOneWidget);
    await tester.tap(checkoutButton);
    await tester.pumpAndSettle();

    // Verify receipt success dialog appears with print option
    expect(find.text('Thanh toán thành công!'), findsOneWidget);
    expect(find.textContaining('ORD-POS-20261029-99'), findsOneWidget);
    expect(find.text('In hóa đơn'), findsOneWidget);
    expect(find.text('Tạo đơn tiếp theo'), findsOneWidget);

    await tester.tap(find.text('In hóa đơn'));
    await tester.pump();

    await tester.tap(find.text('Tạo đơn tiếp theo'));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán thành công!'), findsNothing);
  });

  testWidgets('PosCashierView opens VNPay QR dialog when QR payment is selected', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final vnPayService = VnPayService(apiClient);

    await tester.pumpWidget(
      MaterialApp(
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: PosCashierView(
            orderService: orderService,
            productService: productService,
            userService: userService,
            vnPayService: vnPayService,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Add product to cart
    final addIcon = find.byTooltip('Thêm vào đơn');
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // Select QR payment method
    final qrButton = find.text('QR/CK');
    expect(qrButton, findsOneWidget);
    await tester.tap(qrButton);
    await tester.pumpAndSettle();

    // Tap Checkout
    final checkoutButton = find.text('Thanh toán 28.000.000 ₫');
    await tester.tap(checkoutButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify VNPay QR Dialog opened
    expect(find.text('Quét mã VNPAY / VietQR'), findsOneWidget);
    expect(find.text('Mở Popup VNPAY'), findsOneWidget);
    expect(find.text('Xác nhận nhận tiền'), findsOneWidget);

    // Click confirm manual payment (opens manual audit dialog)
    await tester.tap(find.text('Xác nhận nhận tiền'));
    await tester.pumpAndSettle();

    expect(find.text('Xác thực thanh toán thủ công'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'MBBANK-REF-9988');
    await tester.tap(find.text('Xác nhận & Lưu vết'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify order completed with single dialog and print option
    expect(find.text('Thanh toán thành công!'), findsOneWidget);
    expect(find.text('In hóa đơn'), findsOneWidget);
    expect(find.text('Tạo đơn tiếp theo'), findsOneWidget);

    await tester.tap(find.text('In hóa đơn'));
    await tester.pump();

    await tester.tap(find.text('Tạo đơn tiếp theo'));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán thành công!'), findsNothing);
  });
}
