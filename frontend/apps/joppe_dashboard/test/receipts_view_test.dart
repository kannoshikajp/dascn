import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/localization/dashboard_localizations.dart';
import 'package:joppe_dashboard/src/views/receipts_view.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late InventoryService inventoryService;
  late ProductManagementService productService;

  final sampleReceipts = [
    {
      'id': 'rec-inb-1',
      'receiptCode': 'REC-20261101-AAA11',
      'receiptType': 'INBOUND',
      'supplierId': 'sup-1',
      'supplierName': 'Viettel Distribution',
      'orderId': null,
      'orderCode': null,
      'staffId': 'staff-1',
      'staffName': 'Staff Alice',
      'totalAmount': 150000000.0,
      'totalItems': 10,
      'status': 'COMPLETED',
      'createdAt': '2026-11-01T08:00:00Z',
      'note': null,
    },
    {
      'id': 'rec-out-1',
      'receiptCode': 'OUT-20261101-BBB22',
      'receiptType': 'OUTBOUND',
      'supplierId': null,
      'supplierName': null,
      'orderId': 'ord-1',
      'orderCode': 'ORD-20261101-ONLINE99',
      'staffId': 'user-1',
      'staffName': 'Customer Online',
      'totalAmount': 45000000.0,
      'totalItems': 2,
      'status': 'COMPLETED',
      'createdAt': '2026-11-01T09:30:00Z',
      'note': 'Auto outbound for order ORD-20261101-ONLINE99',
    },
    {
      'id': 'rec-inb-draft',
      'receiptCode': 'REC-20261101-CCC33',
      'receiptType': 'INBOUND',
      'supplierId': 'sup-2',
      'supplierName': 'FPT Synnex',
      'orderId': null,
      'orderCode': null,
      'staffId': 'staff-2',
      'staffName': 'Staff Bob',
      'totalAmount': 32000000.0,
      'totalItems': 5,
      'status': 'DRAFT',
      'createdAt': '2026-11-01T10:00:00Z',
      'note': null,
    },
  ];

  setUp(() {
    mockClient = MockClient((request) async {
      if (request.url.path == '/api/v1/admin/inventory/receipts') {
        return http.Response(
          jsonEncode(sampleReceipts),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/inventory/suppliers') {
        return http.Response(
          jsonEncode([
            {
              'id': 'sup-1',
              'supplierName': 'Viettel Distribution',
              'contactPerson': 'Nguyen Van Distro',
              'phoneNumber': '0901234567',
              'email': 'distro@viettel.vn',
              'address': 'Hanoi, Vietnam',
              'isActive': true,
              'createdAt': '2026-10-22T08:00:00Z',
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/inventory/receipts/rec-inb-1') {
        return http.Response(
          jsonEncode({
            ...sampleReceipts[0],
            'items': [
              {
                'id': 'item-1',
                'variantId': 'var-1',
                'productName': 'Intel Core i9-14900K',
                'variantName': 'Tray',
                'sku': 'CPU-14900K',
                'thumbnailUrl': null,
                'quantity': 10,
                'importPrice': 15000000.0,
                'subtotal': 150000000.0,
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
    inventoryService = InventoryService(apiClient);
    productService = ProductManagementService(apiClient);
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
        body: ReceiptsView(
          inventoryService: inventoryService,
          productService: productService,
        ),
      ),
    );
  }

  testWidgets('renders ReceiptsView with KPI metrics and receipts table', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify KPI cards
    expect(find.text('Total Receipts'), findsOneWidget);
    expect(find.text('Total Inbound Value'), findsOneWidget);
    expect(find.text('Total Outbound Value'), findsOneWidget);
    expect(find.text('Total Units'), findsOneWidget);

    // Verify values: 3 receipts, 17 items total
    expect(find.text('3'), findsWidgets);
    expect(find.text('17'), findsWidgets);

    // Verify table items
    expect(find.text('REC-20261101-AAA11'), findsOneWidget);
    expect(find.text('Viettel Distribution'), findsWidgets);
    expect(find.text('OUT-20261101-BBB22'), findsOneWidget);
    expect(find.text('ORD-20261101-ONLINE99'), findsOneWidget);
    expect(find.text('REC-20261101-CCC33'), findsOneWidget);

    // Verify badges
    expect(find.text('Inbound'), findsWidgets);
    expect(find.text('Outbound'), findsWidgets);
    expect(find.text('COMPLETED'), findsWidgets);
    expect(find.text('DRAFT'), findsWidgets);
  });

  testWidgets('filters receipts by movement type pills', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // All visible initially
    expect(find.text('REC-20261101-AAA11'), findsOneWidget);
    expect(find.text('OUT-20261101-BBB22'), findsOneWidget);

    // Tap 'Outbound' pill
    final outboundPill = find.widgetWithText(FilterChip, 'Outbound');
    await tester.tap(outboundPill);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Only Outbound should be visible
    expect(find.text('OUT-20261101-BBB22'), findsOneWidget);
    expect(find.text('REC-20261101-AAA11'), findsNothing);

    // Tap 'Inbound' pill
    final inboundPill = find.widgetWithText(FilterChip, 'Inbound');
    await tester.tap(inboundPill);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Inbound items visible, Outbound gone
    expect(find.text('REC-20261101-AAA11'), findsOneWidget);
    expect(find.text('OUT-20261101-BBB22'), findsNothing);
  });

  testWidgets('filters receipts via search input and clear button', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Enter search query 'ONLINE99'
    await tester.enterText(find.byType(TextField).first, 'ONLINE99');
    await tester.pump();

    expect(find.text('OUT-20261101-BBB22'), findsOneWidget);
    expect(find.text('REC-20261101-AAA11'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.text('REC-20261101-AAA11'), findsOneWidget);
    expect(find.text('OUT-20261101-BBB22'), findsOneWidget);
  });

  testWidgets('opens receipt detail modal on clicking View button', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap 'View' button for first receipt
    final viewButtons = find.text('View');
    expect(viewButtons, findsWidgets);

    await tester.ensureVisible(viewButtons.first);
    await tester.tap(viewButtons.first);
    await tester.pumpAndSettle();

    // Verify detail dialog contents
    expect(find.textContaining('Supplier: Viettel Distribution'), findsOneWidget);
    expect(find.text('Intel Core i9-14900K • Tray'), findsOneWidget);
    expect(find.text('Total Amount:'), findsOneWidget);
  });

  testWidgets('renders properly with Vietnamese locale', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject(locale: const Locale('vi')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tổng số phiếu'), findsOneWidget);
    expect(find.text('Tổng giá trị nhập'), findsOneWidget);
    expect(find.text('Tổng giá trị xuất'), findsOneWidget);
    expect(find.text('Nhập kho'), findsWidgets);
    expect(find.text('Xuất kho'), findsWidgets);
    expect(find.text('Mã phiếu'), findsOneWidget);
    expect(find.text('Loại phiếu'), findsWidgets);
    expect(find.text('NCC / Đơn hàng'), findsOneWidget);
  });
}
