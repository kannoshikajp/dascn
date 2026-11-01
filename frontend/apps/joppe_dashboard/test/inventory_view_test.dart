import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/views/inventory_view.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late InventoryService inventoryService;
  late ProductManagementService productService;

  setUp(() {
    mockClient = MockClient((request) async {
      if (request.url.path == '/api/v1/admin/inventory/stock') {
        return http.Response(
          jsonEncode([
            {
              'variantId': 'var-1',
              'productId': 'prod-1',
              'productName': 'Intel Core i9-14900K',
              'variantName': 'Tray No Fan',
              'sku': 'CPU-INTEL-14900K-TRAY',
              'variantCode': '14900K-TRAY',
              'thumbnailUrl': null,
              'salePrice': 14500000.0,
              'listPrice': 15500000.0,
              'quantityOnHand': 5,
              'quantityReserved': 1,
              'stockAvailable': 4,
              'reorderLevel': 10,
              'isLowStock': true,
              'isOutOfStock': false,
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/inventory/receipts') {
        return http.Response(
          jsonEncode([
            {
              'id': 'rec-1',
              'receiptCode': 'REC-20261022-TEST1',
              'supplierId': 'sup-1',
              'supplierName': 'Viettel Distribution',
              'staffId': 'staff-1',
              'staffName': 'Staff A',
              'totalAmount': 145000000.0,
              'totalItems': 10,
              'status': 'COMPLETED',
              'createdAt': '2026-10-22T08:00:00Z',
            }
          ]),
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
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });

    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    inventoryService = InventoryService(apiClient);
    productService = ProductManagementService(apiClient);
  });

  testWidgets('renders InventoryView with tabs and stock table', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: InventoryView(
            inventoryService: inventoryService,
            productService: productService,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Inventory & Supply Chain'), findsOneWidget);
    expect(find.text('Warehouse'), findsOneWidget);
    expect(find.text('Goods Receipts (Inbound)'), findsOneWidget);
    expect(find.text('Suppliers Directory'), findsOneWidget);

    // Stock item rendered
    expect(find.text('Intel Core i9-14900K'), findsOneWidget);
    expect(find.text('CPU-INTEL-14900K-TRAY'), findsOneWidget);
    expect(find.text('Low Stock (4/10)'), findsOneWidget);
  });

  testWidgets('switches to Receipts tab and renders receipts list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: InventoryView(
            inventoryService: inventoryService,
            productService: productService,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Receipts tab
    final receiptsTab = find.text('Goods Receipts (Inbound)');
    await tester.tap(receiptsTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('REC-20261022-TEST1'), findsOneWidget);
    expect(find.text('Viettel Distribution'), findsWidgets);
    expect(find.text('COMPLETED'), findsWidgets);
  });

  testWidgets('switches to Suppliers tab and renders suppliers list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: JoppeTheme.light(),
        home: Scaffold(
          body: InventoryView(
            inventoryService: inventoryService,
            productService: productService,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Suppliers tab
    final suppliersTab = find.text('Suppliers Directory');
    await tester.tap(suppliersTab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Add Supplier'), findsOneWidget);
    expect(find.text('Viettel Distribution'), findsWidgets);
    expect(find.text('Nguyen Van Distro'), findsOneWidget);
    expect(find.text('distro@viettel.vn'), findsOneWidget);
  });
}
