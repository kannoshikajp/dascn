import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joppe_app/src/data/hardware_mock_data.dart';
import 'package:joppe_app/src/models/cart_item.dart';
import 'package:joppe_app/src/models/order.dart';
import 'package:joppe_app/src/screens/build_pc_screen.dart';
import 'package:joppe_app/src/screens/cart_screen.dart';
import 'package:joppe_app/src/screens/order_success_screen.dart';
import 'package:joppe_app/src/screens/product_details_screen.dart';
import 'package:joppe_app/src/services/cart_service.dart';

void main() {
  setUp(() {
    CartService().reset();
  });

  tearDown(() {
    CartService().reset();
  });

  group('RenderFlex Overflow Prevention Tests on Mobile Screens', () {
    testWidgets('ProductDetailsScreen renders without RenderFlex overflow on 360x640 mobile screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final product = HardwareMockData.products.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsScreen(product: product),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('ĐÁNH GIÁ TỪ KHÁCH HÀNG'), findsOneWidget);
      expect(find.text('VIẾT ĐÁNH GIÁ'), findsOneWidget);
    });

    testWidgets('ProductDetailsScreen renders without RenderFlex overflow on ultra-narrow 320x568 screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final product = HardwareMockData.products.first;

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsScreen(product: product),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('ĐÁNH GIÁ TỪ KHÁCH HÀNG'), findsOneWidget);
      expect(find.text('VIẾT ĐÁNH GIÁ'), findsOneWidget);
    });

    testWidgets('CartScreen renders items and bottom bar without RenderFlex overflow on 360x640 screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      CartService().addItem(HardwareMockData.products[0]);
      CartService().addItem(HardwareMockData.products[1]);

      await tester.pumpWidget(
        const MaterialApp(
          home: CartScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('TIẾN HÀNH THANH TOÁN'), findsOneWidget);
    });

    testWidgets('BuildPcScreen renders all 8 component slots without RenderFlex overflow on 360x640 screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: BuildPcScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('XÂY DỰNG CẤU HÌNH PC'), findsOneWidget);
      expect(find.text('Đã chọn: 0/8 linh kiện chính'), findsOneWidget);
      expect(find.text('Đang xây dựng'), findsOneWidget);
      expect(find.text('CPU - Bộ Vi Xử Lý'), findsOneWidget);
      expect(find.text('Mainboard - Bo Mạch Chủ'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('VGA - Card Đồ Họa'), 200);
      expect(find.text('VGA - Card Đồ Họa'), findsOneWidget);
    });

    testWidgets('OrderSuccessScreen renders without RenderFlex overflow on 360x640 screen with long ID', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final order = Order(
        orderId: 'c0a80123-4567-89ab-cdef-0123456789ab-long-order-id',
        customerName: 'Nguyễn Trần Đình Trung Kiên',
        phoneNumber: '0987654321',
        email: 'test@joppe.vn',
        shippingAddress: 'Số 123 Đường Công Nghệ, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
        shippingMethod: ShippingMethod.express,
        paymentMethod: PaymentMethodType.vietQr,
        items: [
          CartItem(
            product: HardwareMockData.products.first,
            quantity: 2,
          ),
        ],
        subtotal: 50000000,
        shippingFee: 0,
        grandTotal: 50000000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OrderSuccessScreen(order: order),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('MÃ ĐƠN HÀNG: '), findsOneWidget);
    });
  });
}
