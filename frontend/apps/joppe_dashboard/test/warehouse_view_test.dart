import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/localization/dashboard_localizations.dart';
import 'package:joppe_dashboard/src/views/warehouse_view.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late InventoryService inventoryService;

  final sampleStockItems = [
    {
      'variantId': 'var-1',
      'productId': 'prod-1',
      'productName': 'Intel Core i9-14900K',
      'variantName': 'Tray No Fan',
      'sku': 'CPU-INTEL-14900K-TRAY',
      'thumbnailUrl': null,
      'salePrice': 14500000.0,
      'listPrice': 15500000.0,
      'quantityOnHand': 5,
      'quantityReserved': 1,
      'stockAvailable': 4,
      'reorderLevel': 10,
      'isLowStock': true,
      'isOutOfStock': false,
    },
    {
      'variantId': 'var-2',
      'productId': 'prod-2',
      'productName': 'GeForce RTX 4090',
      'variantName': '24GB GDDR6X',
      'sku': 'GPU-RTX4090-24G',
      'thumbnailUrl': null,
      'salePrice': 52000000.0,
      'listPrice': 55000000.0,
      'quantityOnHand': 0,
      'quantityReserved': 0,
      'stockAvailable': 0,
      'reorderLevel': 5,
      'isLowStock': false,
      'isOutOfStock': true,
    },
    {
      'variantId': 'var-3',
      'productId': 'prod-3',
      'productName': 'Kingston Fury Beast',
      'variantName': '32GB DDR5 6000MHz',
      'sku': 'RAM-KF-32G-6000',
      'thumbnailUrl': null,
      'salePrice': 3200000.0,
      'listPrice': 3500000.0,
      'quantityOnHand': 50,
      'quantityReserved': 2,
      'stockAvailable': 48,
      'reorderLevel': 15,
      'isLowStock': false,
      'isOutOfStock': false,
    },
  ];

  setUp(() {
    mockClient = MockClient((request) async {
      if (request.url.path == '/api/v1/admin/inventory/stock') {
        if (request.url.queryParameters['lowStockOnly'] == 'true') {
          return http.Response(
            jsonEncode([sampleStockItems[0]]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(sampleStockItems),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/inventory/stock/var-1' &&
          request.method == 'PATCH') {
        return http.Response(
          jsonEncode({
            ...sampleStockItems[0],
            'quantityOnHand': 20,
            'stockAvailable': 19,
            'isLowStock': false,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });

    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    inventoryService = InventoryService(apiClient);
  });

  Widget createSubject({Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('vi')],
      localizationsDelegates: const [
        DashboardLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: JoppeTheme.light(),
      home: Scaffold(
        body: WarehouseView(inventoryService: inventoryService),
      ),
    );
  }

  testWidgets('renders WarehouseView with KPI cards and stock table', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify KPI cards
    expect(find.text('Total Variants'), findsOneWidget);
    expect(find.text('Low Stock Alert'), findsOneWidget);
    expect(find.text('Out of Stock'), findsWidgets);
    expect(find.text('Warehouse Valuation'), findsOneWidget);

    // Verify values: 3 variants, 1 low stock, 1 out of stock
    expect(find.text('3'), findsWidgets);
    expect(find.text('1'), findsWidgets);

    // Verify table items
    expect(find.text('Intel Core i9-14900K'), findsOneWidget);
    expect(find.text('CPU-INTEL-14900K-TRAY'), findsOneWidget);
    expect(find.text('GeForce RTX 4090'), findsOneWidget);
    expect(find.text('GPU-RTX4090-24G'), findsOneWidget);
    expect(find.text('Kingston Fury Beast'), findsOneWidget);

    // Verify status badges
    expect(find.text('Low Stock (4/10)'), findsOneWidget);
    expect(find.text('In Stock'), findsWidgets);
  });

  testWidgets('filters stock items by status pills', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // All 3 items visible initially
    expect(find.text('Intel Core i9-14900K'), findsOneWidget);
    expect(find.text('GeForce RTX 4090'), findsOneWidget);
    expect(find.text('Kingston Fury Beast'), findsOneWidget);

    // Tap 'Out of Stock' pill
    final outOfStockPill = find.widgetWithText(FilterChip, 'Out of Stock');
    await tester.tap(outOfStockPill);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Only RTX 4090 should be visible
    expect(find.text('GeForce RTX 4090'), findsOneWidget);
    expect(find.text('Intel Core i9-14900K'), findsNothing);
    expect(find.text('Kingston Fury Beast'), findsNothing);

    // Tap 'In Stock' pill
    final inStockPill = find.widgetWithText(FilterChip, 'In Stock');
    await tester.tap(inStockPill);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Only Kingston Fury Beast should be visible
    expect(find.text('Kingston Fury Beast'), findsOneWidget);
    expect(find.text('Intel Core i9-14900K'), findsNothing);
    expect(find.text('GeForce RTX 4090'), findsNothing);
  });

  testWidgets('filters stock items via search input and clear button', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Enter query 'RTX'
    await tester.enterText(find.byType(TextField).first, 'RTX');
    await tester.pump();

    expect(find.text('GeForce RTX 4090'), findsOneWidget);
    expect(find.text('Intel Core i9-14900K'), findsNothing);

    // Clear search using clear button
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    // All items restored
    expect(find.text('Intel Core i9-14900K'), findsOneWidget);
    expect(find.text('GeForce RTX 4090'), findsOneWidget);
    expect(find.text('Kingston Fury Beast'), findsOneWidget);
  });

  testWidgets('opens 3-dot action menu and displays row actions', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Find and tap first 3-dot menu button
    final moreButtons = find.byIcon(Icons.more_vert_rounded);
    expect(moreButtons, findsWidgets);

    await tester.ensureVisible(moreButtons.first);
    await tester.tap(moreButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Adjust Stock'), findsOneWidget);
    expect(find.text('Copy SKU'), findsOneWidget);
  });

  testWidgets('opens adjust stock dialog and saves adjustments', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Open 3-dot menu
    final moreButtons = find.byIcon(Icons.more_vert_rounded);
    await tester.ensureVisible(moreButtons.first);
    await tester.tap(moreButtons.first);
    await tester.pumpAndSettle();

    // Tap Adjust Stock
    await tester.tap(find.text('Adjust Stock'));
    await tester.pumpAndSettle();

    // Dialog opens with current stock info
    expect(find.text('Adjust Stock & Threshold'), findsOneWidget);
    expect(find.text('Intel Core i9-14900K'), findsWidgets);
    expect(find.text('CPU-INTEL-14900K-TRAY'), findsWidgets);

    // Tap Save button
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Adjust Stock & Threshold'), findsNothing);
  });

  testWidgets('renders properly with Vietnamese locale', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject(locale: const Locale('vi')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tổng phiên bản'), findsOneWidget);
    expect(find.text('Cảnh báo sắp hết'), findsOneWidget);
    expect(find.text('Định giá kho'), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('Sản phẩm & Phiên bản'), findsOneWidget);
    expect(find.text('Đơn giá'), findsOneWidget);
    expect(find.text('Thực tế'), findsOneWidget);
    expect(find.text('Khả dụng'), findsOneWidget);
  });

  testWidgets('constrains very long product name within bounded cell width with ellipsis', (tester) async {
    final longNamedMockClient = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'variantId': 'var-long',
            'productId': 'prod-long',
            'productName': 'Super Ultra Extra Extremely Long Name That Could Blow Out Any Layout On A Modern Display Interface Mainboard ASUS ROG Maximus Extreme Edition',
            'variantName': 'Variant Name With Extreme Details DDR5 RGB Overclocked 10000MHz',
            'sku': 'SKU-EXTREMELY-LONG-IDENTIFIER-CODE-FOR-HARDWARE-PART-2026',
            'thumbnailUrl': null,
            'salePrice': 99000000.0,
            'listPrice': 105000000.0,
            'quantityOnHand': 10,
            'quantityReserved': 2,
            'stockAvailable': 8,
            'reorderLevel': 5,
            'isLowStock': false,
            'isOutOfStock': false,
          }
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final longInventoryService = InventoryService(ApiClient(baseUrl: 'http://localhost:8080', client: longNamedMockClient));

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WarehouseView(inventoryService: longInventoryService),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Find the SizedBox holding the cell content
    final cellSizedBox = tester.widget<SizedBox>(find.byWidgetPredicate(
      (w) => w is SizedBox && w.width == 240,
    ).first);
    expect(cellSizedBox.width, 240);

    // Verify text widget has maxLines 2 and ellipsis
    final productText = tester.widget<Text>(find.textContaining('Super Ultra Extra Extremely Long Name').first);
    expect(productText.maxLines, 2);
    expect(productText.overflow, TextOverflow.ellipsis);
  });
}
