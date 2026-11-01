import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/localization/dashboard_localizations.dart';
import 'package:joppe_dashboard/src/views/orders_view.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late OrderService orderService;

  setUp(() {
    mockClient = MockClient((request) async {
      if (request.url.path == '/api/v1/admin/orders') {
        return http.Response(
          jsonEncode([
            {
              'id': 'ord-1-uuid',
              'orderCode': 'ORD-20261022-ABC12',
              'userId': 'user-1',
              'orderStatus': 'ACCEPTED',
              'paymentStatus': 'PAID',
              'recipientName': 'Tran Van B',
              'recipientPhone': '0912345678',
              'finalAmount': 25000000.0,
              'totalItems': 2,
              'createdAt': '2026-10-22T09:30:00Z',
              'updatedAt': '2026-10-22T09:30:00Z',
            },
            {
              'id': 'ord-2-uuid',
              'orderCode': 'ORD-20261022-XYZ89',
              'userId': 'user-2',
              'orderStatus': 'SHIPPED',
              'paymentStatus': 'PAID',
              'recipientName': 'Le Thi C',
              'recipientPhone': '0987654321',
              'finalAmount': 42000000.0,
              'totalItems': 1,
              'createdAt': '2026-10-22T08:00:00Z',
              'updatedAt': '2026-10-22T10:00:00Z',
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/orders/ord-1-uuid') {
        return http.Response(
          jsonEncode({
            'id': 'ord-1-uuid',
            'orderCode': 'ORD-20261022-ABC12',
            'userId': 'user-1',
            'orderStatus': 'ACCEPTED',
            'paymentStatus': 'PAID',
            'recipientName': 'Tran Van B',
            'recipientPhone': '0912345678',
            'shippingAddress': '456 Cyber St, Q1, HCMC',
            'subtotalAmount': 25000000.0,
            'discountAmount': 0.0,
            'shippingFee': 0.0,
            'finalAmount': 25000000.0,
            'customerNote': 'Handle with care',
            'createdAt': '2026-10-22T09:30:00Z',
            'updatedAt': '2026-10-22T09:30:00Z',
            'items': [
              {
                'id': 'item-1',
                'variantId': 'var-1',
                'skuSnapshot': 'GPU-4080S',
                'productNameSnapshot': 'RTX 4080 Super',
                'variantNameSnapshot': '16GB OC',
                'quantity': 1,
                'unitPrice': 25000000.0,
                'subtotal': 25000000.0,
                'warrantyMonthsSnapshot': 36,
                'thumbnailUrl': null,
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });

    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    orderService = OrderService(apiClient);
  });

  testWidgets('renders OrdersView with KPI metrics and order rows', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: OrdersView(orderService: orderService),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Orders & Fulfillment'), findsOneWidget);
    expect(find.text('ORD-20261022-ABC12'), findsOneWidget);
    expect(find.text('Tran Van B'), findsOneWidget);
    expect(find.text('ORD-20261022-XYZ89'), findsOneWidget);
    expect(find.text('Le Thi C'), findsOneWidget);

    // Filter chips
    expect(find.text('ACCEPTED'), findsWidgets);
    expect(find.text('SHIPPED'), findsWidgets);
  });

  testWidgets('opens order detail dialog on clicking View button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: OrdersView(orderService: orderService),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final viewButtons = find.text('View');
    expect(viewButtons, findsWidgets);

    await tester.tap(viewButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify dialog content
    expect(find.text('Shipping Details'), findsOneWidget);
    expect(find.text('456 Cyber St, Q1, HCMC'), findsOneWidget);
    expect(find.text('RTX 4080 Super'), findsOneWidget);
    expect(find.text('Handle with care'), findsOneWidget);
  });

  testWidgets('renders OrdersView in Vietnamese with localized labels and dialog', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: const [
          Locale('vi'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          DashboardLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: OrdersView(orderService: orderService),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Đơn hàng & Vận hành'), findsOneWidget);
    expect(find.text('Tổng đơn hàng'), findsOneWidget);
    expect(find.text('Chờ xử lý'), findsOneWidget);
    expect(find.text('Đang vận chuyển'), findsOneWidget);
    expect(find.text('Doanh thu đã giao'), findsOneWidget);

    // Localized filter chips
    expect(find.text('Đã tiếp nhận'), findsWidgets);
    expect(find.text('Đã nhận hàng'), findsWidgets);

    // View action button in Vietnamese
    final viewButtons = find.text('Chi tiết');
    expect(viewButtons, findsWidgets);

    await tester.tap(viewButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Thông tin giao hàng'), findsOneWidget);
    expect(find.text('Ghi chú khách hàng'), findsOneWidget);
    expect(find.text('Danh sách mặt hàng'), findsOneWidget);
    expect(find.text('Tổng thanh toán:'), findsOneWidget);
  });

  testWidgets('supports multi-toggle pill filtering for orders', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: OrdersView(orderService: orderService),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Both orders visible initially
    expect(find.text('ORD-20261022-ABC12'), findsOneWidget);
    expect(find.text('ORD-20261022-XYZ89'), findsOneWidget);

    // Toggle ACCEPTED pill on
    final acceptedPill = find.widgetWithText(FilterChip, 'ACCEPTED');
    expect(acceptedPill, findsOneWidget);
    await tester.tap(acceptedPill);
    await tester.pumpAndSettle();

    // Only ACCEPTED order visible
    expect(find.text('ORD-20261022-ABC12'), findsOneWidget);
    expect(find.text('ORD-20261022-XYZ89'), findsNothing);

    // Multi-toggle: toggle SHIPPED pill on as well
    final shippedPill = find.widgetWithText(FilterChip, 'SHIPPED');
    expect(shippedPill, findsOneWidget);
    await tester.tap(shippedPill);
    await tester.pumpAndSettle();

    // Both are now visible because both pills are selected (OR filter)
    expect(find.text('ORD-20261022-ABC12'), findsOneWidget);
    expect(find.text('ORD-20261022-XYZ89'), findsOneWidget);

    // Toggle ALL pill to clear multi-selection
    final allPill = find.widgetWithText(FilterChip, 'ALL');
    await tester.tap(allPill.first);
    await tester.pumpAndSettle();

    expect(find.text('ORD-20261022-ABC12'), findsOneWidget);
    expect(find.text('ORD-20261022-XYZ89'), findsOneWidget);
  });

  testWidgets('OrdersTable supports vertical scrolling when content exceeds height', (WidgetTester tester) async {
    // Compact laptop screen height to exercise vertical scroll on table
    tester.view.physicalSize = const Size(1280, 550);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: OrdersView(orderService: orderService),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Finds vertical scrollable inside OrdersTable
    final scrollables = find.byType(SingleChildScrollView);
    expect(scrollables, findsWidgets);

    // Scroll vertically without errors or RenderFlex overflow
    await tester.drag(scrollables.first, const Offset(0, -150));
    await tester.pump();
  });

  testWidgets('button before reset toggles show and hide of filter pill options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: OrdersView(orderService: orderService),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Initially filter pills are visible
    expect(find.text('Order Status: '), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'ACCEPTED'), findsOneWidget);

    // Tap toggle button (before reset button)
    final toggleFilterButton = find.widgetWithText(FilledButton, 'Filter');
    expect(toggleFilterButton, findsOneWidget);
    await tester.tap(toggleFilterButton);
    await tester.pumpAndSettle();

    // Now filter pills are hidden
    expect(find.text('Order Status: '), findsNothing);
    expect(find.widgetWithText(FilterChip, 'ACCEPTED'), findsNothing);

    // Tap again to show filter pills
    await tester.tap(toggleFilterButton);
    await tester.pumpAndSettle();

    // Filter pills are visible again
    expect(find.text('Order Status: '), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'ACCEPTED'), findsOneWidget);
  });
}
