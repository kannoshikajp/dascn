import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/localization/dashboard_localizations.dart';
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
      if (request.url.path == '/api/v1/admin/categories/export') {
        return http.Response(
          'ID,Category Name,Slug\n1,Laptops,laptops\n',
          200,
          headers: {'content-type': 'text/csv; charset=utf-8'},
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

  testWidgets('renders KPI cards summarizing categories metrics', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Total categories = 2, root categories = 1, active = 2, total products = 16
    expect(find.text('Total Categories'), findsOneWidget);
    expect(find.text('Root Categories'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Linked Products'), findsOneWidget);
    expect(find.text('16'), findsOneWidget);
  });

  testWidgets('toggles filter options visibility with filter button', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Filter options are visible by default in Tree mode (Status pills + Expand/Collapse)
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Expand All'), findsOneWidget);
    expect(find.text('All Levels'), findsNothing);

    // Switch to List mode: 'All Levels' (Cap Bac) appears
    await tester.tap(find.text('List'));
    await tester.pump();
    expect(find.text('All Levels'), findsOneWidget);

    // Tap toggle filter button to hide
    await tester.tap(find.text('Filter'));
    await tester.pump();

    expect(find.text('All'), findsNothing);
    expect(find.text('All Levels'), findsNothing);

    // Tap toggle filter button to show again
    await tester.tap(find.text('Filter'));
    await tester.pump();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('All Levels'), findsOneWidget);
  });

  testWidgets('expands all and collapses all tree nodes correctly', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Initially depth 0 is expanded: Gaming Laptops is visible and chevron indicates expanded state
    expect(find.text('Gaming Laptops'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

    // Tap 'Collapse All' button
    await tester.tap(find.text('Collapse All'));
    await tester.pumpAndSettle();

    // Now Gaming Laptops should be collapsed and chevron indicates collapsed state
    expect(find.text('Gaming Laptops'), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_right_rounded), findsOneWidget);

    // Tap 'Expand All' button
    await tester.tap(find.text('Expand All'));
    await tester.pumpAndSettle();

    // Gaming Laptops should be visible again and chevron points down
    expect(find.text('Gaming Laptops'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

    // Tap 'Collapse All' button again to verify repeatable state change
    await tester.tap(find.text('Collapse All'));
    await tester.pumpAndSettle();

    expect(find.text('Gaming Laptops'), findsNothing);
  });

  testWidgets('three-dot action menu opens and displays row actions', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Three-dot buttons should be rendered for category nodes
    final moreButtons = find.byIcon(Icons.more_vert_rounded);
    expect(moreButtons, findsWidgets);

    // Tap the first three-dot menu button
    await tester.tap(moreButtons.first);
    await tester.pumpAndSettle();

    // Verify popup menu items appear
    expect(find.text('Add Subcategory'), findsOneWidget);
    expect(find.text('Edit Category'), findsOneWidget);
    expect(find.text('Deactivate'), findsOneWidget);
    expect(find.text('Delete Category'), findsOneWidget);
  });

  testWidgets('renders properly with Vietnamese locale', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        DashboardLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: CategoriesView(categoryService: categoryService),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Tổng danh mục'), findsOneWidget);
    expect(find.text('Danh mục gốc'), findsOneWidget);
    expect(find.text('Thêm danh mục'), findsOneWidget);
    expect(find.text('Dạng cây'), findsOneWidget);
    expect(find.text('Dạng bảng'), findsOneWidget);
    expect(find.text('10 sản phẩm'), findsOneWidget);
  });

  testWidgets('renders Export CSV button and handles category export', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: const [
        DashboardLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: CategoriesView(categoryService: categoryService),
      ),
    ));
    await tester.pumpAndSettle();

    final exportBtn = find.widgetWithText(OutlinedButton, 'Xuất CSV');
    expect(exportBtn, findsOneWidget);

    await tester.tap(exportBtn);
    await tester.pumpAndSettle();

    expect(find.text('Xuất file CSV thành công'), findsOneWidget);
  });
}
