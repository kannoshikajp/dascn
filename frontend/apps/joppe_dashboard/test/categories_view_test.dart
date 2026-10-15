import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/views/categories_view.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late CategoryManagementService categoryService;

  setUp(() {
    mockClient = MockClient((request) async {
      if (request.url.path == '/api/v1/admin/categories/tree') {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'parentId': null,
              'categoryName': 'Laptops',
              'slug': 'laptops',
              'iconUrl': null,
              'isActive': true,
              'productCount': 10,
              'children': [
                {
                  'id': 2,
                  'parentId': 1,
                  'categoryName': 'Gaming Laptops',
                  'slug': 'gaming-laptops',
                  'iconUrl': null,
                  'isActive': true,
                  'productCount': 6,
                  'children': [],
                }
              ],
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
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
              'createdAt': '2026-03-30T10:00:00Z',
              'productCount': 10,
              'childCount': 1,
            },
            {
              'id': 2,
              'parentId': 1,
              'parentName': 'Laptops',
              'categoryName': 'Gaming Laptops',
              'slug': 'gaming-laptops',
              'iconUrl': null,
              'isActive': true,
              'createdAt': '2026-03-30T10:00:00Z',
              'productCount': 6,
              'childCount': 0,
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/categories/1/status') {
        return http.Response('', 204);
      }
      if (request.url.path == '/api/v1/admin/categories/2' && request.method == 'DELETE') {
        return http.Response('', 204);
      }
      return http.Response('{}', 200, headers: {'content-type': 'application/json'});
    });

    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    categoryService = CategoryManagementService(apiClient);
  });

  Widget createSubject() {
    return MaterialApp(
      home: Scaffold(
        body: CategoriesView(categoryService: categoryService),
      ),
    );
  }

  testWidgets('renders tree hierarchy view with nodes and badges', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Add Category'), findsOneWidget);
    expect(find.text('Laptops'), findsOneWidget);
    expect(find.text('/laptops'), findsOneWidget);
    expect(find.text('10 products'), findsOneWidget);
    expect(find.text('Gaming Laptops'), findsOneWidget);
    expect(find.text('6 products'), findsOneWidget);
  });

  testWidgets('switches to flat list mode and shows tabular cards', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap 'List' segment
    await tester.tap(find.text('List'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('10 products • 1 subcategories'), findsOneWidget);
    expect(find.text('6 products • 0 subcategories'), findsOneWidget);
    expect(find.text('Laptops > '), findsOneWidget);
  });

  testWidgets('opens Add Category dialog on button click', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Add Category'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Add New Category'), findsOneWidget);
    expect(find.text('Category Name'), findsOneWidget);
    expect(find.text('URL Slug'), findsOneWidget);
    expect(find.text('Parent Category'), findsOneWidget);
  });
}
