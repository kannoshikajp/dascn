import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/localization/dashboard_localizations.dart';
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
              'sku': 'SKU-ROG-G16-01',
              'parentSku': null,
              'slug': 'asus-rog-strix-g16',
              'brandId': 1,
              'brandName': 'ASUS',
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
                  'sku': 'SKU-ROG-G16-01',
                  'variantName': 'Default',
                  'thumbnailUrl': null,
                  'description': null,
                  'albumUrls': [],
                  'albumMediaIds': [],
                  'listPrice': 45000000.0,
                  'salePrice': 42000000.0,
                  'quantityOnHand': 12,
                  'quantityReserved': 0,
                  'availableQuantity': 12,
                  'weightGram': 2400.0,
                  'isActive': true,
                }
              ],
            },
            {
              'id': 'p2-uuid',
              'productName': 'Chuột Gaming Logitech G102',
              'sku': 'SKU-LOGI-G102',
              'parentSku': null,
              'slug': 'chuot-gaming-logitech-g102',
              'brandId': 2,
              'brandName': 'Logitech',
              'isActive': true,
              'minPrice': 400000.0,
              'maxPrice': 400000.0,
              'totalStock': 50,
              'categories': [
                {
                  'id': 2,
                  'categoryName': 'Gaming',
                  'slug': 'gaming',
                  'isPrimary': true,
                }
              ],
              'variants': [
                {
                  'id': 'v2-uuid',
                  'sku': 'SKU-LOGI-G102',
                  'variantName': 'Default',
                  'listPrice': 400000.0,
                  'salePrice': 400000.0,
                  'quantityOnHand': 50,
                  'availableQuantity': 50,
                  'isActive': true,
                }
              ],
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/products/export') {
        return http.Response(
          'ID,Product Name,SKU\np1,ASUS,SKU1\n',
          200,
          headers: {'content-type': 'text/csv; charset=utf-8'},
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

  Widget createSubject({Locale locale = const Locale('vi')}) {
    return MaterialApp(
      locale: locale,
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
      home: Scaffold(
        body: ProductsView(
          productService: productService,
          categoryService: categoryService,
        ),
      ),
    );
  }

  testWidgets('renders products view with Vietnamese localization, category pills and price filters', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Quản lý Sản phẩm'), findsOneWidget);
    expect(find.text('Thêm sản phẩm'), findsOneWidget);
    expect(find.text('Danh mục: '), findsOneWidget);
    expect(find.text('Khoảng giá: '), findsOneWidget);

    // Products rendered with price formatting
    expect(find.text('ASUS ROG Strix G16'), findsOneWidget);
    expect(find.text('42.000.000 ₫'), findsOneWidget);
    expect(find.text('Chuột Gaming Logitech G102'), findsOneWidget);
    expect(find.text('400.000 ₫'), findsOneWidget);

    // Category pills present
    expect(find.widgetWithText(FilterChip, 'Laptops'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Gaming'), findsWidgets);

    // Price range preset pills present
    expect(find.widgetWithText(FilterChip, '< 5 Triệu'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '> 30 Triệu'), findsOneWidget);
  });

  testWidgets('filters products by query in search input', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Both products visible initially
    expect(find.text('ASUS ROG Strix G16'), findsOneWidget);
    expect(find.text('Chuột Gaming Logitech G102'), findsOneWidget);

    // Search query 'asus'
    await tester.enterText(find.byType(TextField), 'asus');
    await tester.pumpAndSettle();

    expect(find.text('ASUS ROG Strix G16'), findsOneWidget);
    expect(find.text('Chuột Gaming Logitech G102'), findsNothing);

    // Search query 'logi'
    await tester.enterText(find.byType(TextField), 'logi');
    await tester.pumpAndSettle();

    expect(find.text('ASUS ROG Strix G16'), findsNothing);
    expect(find.text('Chuột Gaming Logitech G102'), findsOneWidget);
  });

  testWidgets('filters products with tri-state pills and AND multi-selection', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final gamingPill = find.widgetWithText(FilterChip, 'Gaming');
    final laptopsPill = find.widgetWithText(FilterChip, 'Laptops');
    expect(gamingPill, findsWidgets);
    expect(laptopsPill, findsOneWidget);

    // 1. Select 'Gaming' (State 1 -> State 2: selected / included)
    // Both ASUS (Gaming + Laptops) and Logitech (Gaming) match
    await tester.tap(gamingPill.first);
    await tester.pumpAndSettle();
    expect(find.text('ASUS ROG Strix G16'), findsOneWidget);
    expect(find.text('Chuột Gaming Logitech G102'), findsOneWidget);

    // 2. Select 'Laptops' as well -> AND logic (the item must have both)
    // Only ASUS has BOTH Gaming and Laptops
    await tester.tap(laptopsPill);
    await tester.pumpAndSettle();
    expect(find.text('ASUS ROG Strix G16'), findsOneWidget);
    expect(find.text('Chuột Gaming Logitech G102'), findsNothing);

    // 3. Click 'Laptops' again (State 2 -> State 3: filter out / except)
    // Item must have Gaming, but must NOT have Laptops
    await tester.tap(laptopsPill);
    await tester.pumpAndSettle();
    expect(find.text('ASUS ROG Strix G16'), findsNothing);
    expect(find.text('Chuột Gaming Logitech G102'), findsOneWidget);

    // 4. Click 'Laptops' 3rd time (State 3 -> State 1: not selected)
    // Back to only Gaming included -> both visible again
    await tester.tap(laptopsPill);
    await tester.pumpAndSettle();
    expect(find.text('ASUS ROG Strix G16'), findsOneWidget);
    expect(find.text('Chuột Gaming Logitech G102'), findsOneWidget);
  });

  testWidgets('filters products by price range tri-state pills', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final under5mPill = find.widgetWithText(FilterChip, '< 5 Triệu');
    expect(under5mPill, findsOneWidget);

    // 1st click: Include < 5 Triệu -> Logitech (400.000 ₫) matches, ASUS (42.000.000 ₫) hidden
    await tester.tap(under5mPill);
    await tester.pumpAndSettle();
    expect(find.text('Chuột Gaming Logitech G102'), findsOneWidget);
    expect(find.text('ASUS ROG Strix G16'), findsNothing);

    // 2nd click: Filter out (except) < 5 Triệu -> Logitech hidden, ASUS matches
    await tester.tap(under5mPill);
    await tester.pumpAndSettle();
    expect(find.text('Chuột Gaming Logitech G102'), findsNothing);
    expect(find.text('ASUS ROG Strix G16'), findsOneWidget);

    // 3rd click: Reset to unselected -> both visible
    await tester.tap(under5mPill);
    await tester.pumpAndSettle();
    expect(find.text('Chuột Gaming Logitech G102'), findsOneWidget);
    expect(find.text('ASUS ROG Strix G16'), findsOneWidget);
  });

  testWidgets('ProductFilterBar wraps category and price pills using Wrap widget', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
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
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: ProductFilterBar(
              searchController: TextEditingController(),
              categories: const [
                CategoryItem(id: 1, categoryName: 'Laptops', slug: 'laptops', productCount: 1, childCount: 0),
                CategoryItem(id: 2, categoryName: 'Gaming Devices', slug: 'gaming', productCount: 1, childCount: 0),
                CategoryItem(id: 3, categoryName: 'Computer Accessories', slug: 'acc', productCount: 1, childCount: 0),
                CategoryItem(id: 4, categoryName: 'Keyboards & Mice', slug: 'km', productCount: 1, childCount: 0),
                CategoryItem(id: 5, categoryName: 'Audio & Headsets', slug: 'audio', productCount: 1, childCount: 0),
              ],
              includedCategoryIds: const {},
              excludedCategoryIds: const {},
              includedPricePresets: const {},
              excludedPricePresets: const {},
              selectedActiveFilter: null,
              onToggleCategory: (_) {},
              onTogglePricePreset: (_) {},
              onSelectStatus: (_) {},
              onClearAllCategories: () {},
              onClearAllPrices: () {},
              onSearchChanged: () {},
              onReset: () {},
              onAddNewProduct: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final wrapFinders = find.byType(Wrap);
    expect(wrapFinders, findsNWidgets(3));
    expect(find.widgetWithText(FilterChip, 'Audio & Headsets'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '> 30 Triệu'), findsOneWidget);
  });

  testWidgets('opens Add Product dialog with localized fields and expands dropdown safely', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Thêm sản phẩm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Thêm sản phẩm mới'), findsOneWidget);
    expect(find.text('Tên sản phẩm *'), findsOneWidget);
    expect(find.text('Mã SKU *'), findsOneWidget);
    expect(find.text('Thuộc nhóm biến thể của (isVariantOf)'), findsOneWidget);
    expect(find.text('Danh mục'), findsOneWidget);
    expect(find.text('Giá & Tồn kho'), findsOneWidget);
    expect(find.text('Giá niêm yết (VND)'), findsOneWidget);
    expect(find.text('Giá bán / Khuyến mãi (VND)'), findsOneWidget);
  });

  testWidgets('opens Edit Product dialog with locked slug and editable price', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final editButtons = find.byIcon(Icons.edit_outlined);
    expect(editButtons, findsWidgets);
    await tester.tap(editButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Chỉnh sửa "ASUS ROG Strix G16"'), findsOneWidget);
    expect(find.text('Đường dẫn URL Slug (Khóa - Không thể sửa)'), findsOneWidget);
    expect(find.text('Giá niêm yết (VND)'), findsOneWidget);
    expect(find.text('Giá bán / Khuyến mãi (VND)'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
  });

  testWidgets('renders Export CSV button and handles export', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    final exportBtn = find.widgetWithText(OutlinedButton, 'Xuất CSV');
    expect(exportBtn, findsOneWidget);

    await tester.tap(exportBtn);
    await tester.pumpAndSettle();

    expect(find.text('Xuất file CSV thành công'), findsOneWidget);
  });
}
