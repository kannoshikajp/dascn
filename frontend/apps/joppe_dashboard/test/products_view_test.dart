import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/views/products_view.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late ProductManagementService productService;
  late CategoryManagementService categoryService;

  setUp(() {
    mockClient = MockClient((request) async {
      if (request.url.path == '/api/v1/admin/categories') {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'parentId': null,
              'parentName': null,
              'categoryName': 'Laptops',
              'slug': 'laptops',
              'iconUrl': null,
              'isActive': true,
              'productCount': 10,
              'childCount': 1,
            },
            {
              'id': 2,
              'parentId': 1,
              'parentName': 'Laptops',
              'categoryName': 'Gaming',
              'slug': 'gaming',
              'iconUrl': null,
              'isActive': true,
              'productCount': 6,
              'childCount': 0,
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/products') {
        return http.Response(
          jsonEncode([
            {
              'id': 'p1-uuid',
              'productName': 'ASUS ROG Strix G16',
              'slug': 'asus-rog-strix-g16',
              'brandId': 1,
              'brandName': 'ASUS',
              'shortDescription': 'Top gaming laptop',
              'warrantyMonths': 24,
              'thumbnailUrl': null,
              'isActive': true,
              'minPrice': 42000000.0,
              'maxPrice': 45000000.0,
              'totalStock': 12,
              'categories': [
                {
                  'id': 1,
                  'categoryName': 'Laptops',
                  'slug': 'laptops',
                  'isPrimary': true,
                },
                {
                  'id': 2,
                  'categoryName': 'Gaming',
                  'slug': 'gaming',
                  'isPrimary': false,
                }
              ],
              'variants': [
                {
                  'id': 'v1-uuid',
                  'sku': 'ROG-G16-01',
                  'variantName': 'Default',
                  'listPrice': 45000000.0,
                  'salePrice': 42000000.0,
                  'quantityOnHand': 12,
                  'quantityReserved': 0,
                  'availableQuantity': 12,
                  'weightGram': 2400.0,
                  'isActive': true,
                }
              ],
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/products/p1-uuid/variants') {
        return http.Response(
          jsonEncode([
            {
              'id': 'v1-uuid',
              'sku': 'ROG-G16-16GB-4060',
              'variantName': '16GB RAM / RTX 4060',
              'attributes': '{"RAM": "16GB", "GPU": "RTX 4060"}',
              'listPrice': 45000000.0,
              'salePrice': 42000000.0,
              'quantityOnHand': 12,
              'quantityReserved': 0,
              'availableQuantity': 12,
              'weightGram': 2400.0,
              'isActive': true,
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/products/p1-uuid/status') {
        return http.Response('', 204);
      }
      if (request.url.path == '/api/v1/admin/products/p1-uuid' && request.method == 'DELETE') {
        return http.Response('', 204);
      }
      return http.Response('{}', 200, headers: {'content-type': 'application/json'});
    });

    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    productService = ProductManagementService(apiClient);
    categoryService = CategoryManagementService(apiClient);
  });

  Widget createSubject() {
    return MaterialApp(
      home: Scaffold(
        body: ProductsView(
          productService: productService,
          categoryService: categoryService,
        ),
      ),
    );
  }

  testWidgets('renders products view with multi-category chips and stock badges', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('ASUS ROG Strix G16'), findsOneWidget);
    expect(find.text('12 in stock'), findsOneWidget);
    expect(find.text('Laptops ★'), findsOneWidget);
    expect(find.text('Gaming'), findsOneWidget);
  });

  testWidgets('opens Add Product dialog and displays multi-category selection list', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Add Product'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Add New Product'), findsOneWidget);
    expect(find.text('Product Name'), findsOneWidget);
    expect(find.text('Categories (Select one or multiple)'), findsOneWidget);
    expect(find.text('Laptops > Gaming'), findsOneWidget);
    expect(find.text('List Price (VND)'), findsOneWidget);
  });

  testWidgets('opens Manage Variants dialog and displays spec attributes', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Variants & Hardware Specs'), findsOneWidget);
    expect(find.text('Add Variant'), findsOneWidget);
  });

  testWidgets('opens Add Spec Variant dialog with dynamic attribute chips', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Add Variant'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Add Spec Variant'), findsOneWidget);
    expect(find.text('Hardware Specs (RAM, GPU, CPU...)'), findsOneWidget);
    expect(find.text('+ RAM'), findsOneWidget);
    expect(find.text('+ GPU'), findsOneWidget);
    expect(find.text('+ CPU'), findsOneWidget);
    expect(find.text('+ Storage'), findsOneWidget);
  });
}
