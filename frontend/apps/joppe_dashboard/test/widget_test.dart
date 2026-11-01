import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/main.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late AuthService authService;
  late UserManagementService userService;
  late RbacManagementService rbacService;
  late CategoryManagementService categoryService;
  late ProductManagementService productService;
  late OrderService orderService;
  late InventoryService inventoryService;
  late AuthSession adminSession;

  setUp(() {
    mockClient = MockClient((request) async {
      if (request.url.path == '/api/v1/auth/me') {
        return http.Response(
          jsonEncode({
            'id': '1',
            'email': 'admin@joppe.vn',
            'fullName': 'System Administrator',
            'phoneNumber': '0901234567',
            'avatarUrl': null,
            'role': 'ROLE_ADMIN',
            'permissions': ['USER_MANAGE', 'ROLE_MANAGE'],
            'isActive': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/users') {
        return http.Response(
          jsonEncode([
            {
              'id': '1',
              'email': 'admin@joppe.vn',
              'fullName': 'System Administrator',
              'phoneNumber': '0901234567',
              'roleId': 1,
              'roleName': 'ROLE_ADMIN',
              'isActive': true,
              'createdAt': '2026-03-30T10:00:00Z',
              'updatedAt': '2026-03-30T10:00:00Z',
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/roles') {
        return http.Response(
          jsonEncode([
            {
              'id': 1,
              'roleName': 'ROLE_ADMIN',
              'description': 'Administrator role',
              'permissions': ['USER_MANAGE', 'ROLE_MANAGE'],
            },
            {
              'id': 2,
              'roleName': 'ROLE_CUSTOMER',
              'description': 'Customer role',
              'permissions': [],
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/permissions') {
        return http.Response(
          jsonEncode([
            {'id': 1, 'permissionName': 'USER_MANAGE', 'description': 'Manage users'},
            {'id': 2, 'permissionName': 'ROLE_MANAGE', 'description': 'Manage roles'},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
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
                  'productCount': 5,
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
              'productCount': 5,
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
              'variants': [],
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/orders') {
        return http.Response(
          jsonEncode([
            {
              'id': 'ord-1-uuid',
              'orderCode': 'ORD-20261022-TEST1',
              'userId': '1',
              'orderStatus': 'PENDING',
              'paymentStatus': 'UNPAID',
              'recipientName': 'Nguyen Van A',
              'recipientPhone': '0901234567',
              'finalAmount': 31900000.0,
              'totalItems': 1,
              'createdAt': '2026-10-22T10:00:00Z',
              'updatedAt': '2026-10-22T10:00:00Z',
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });

    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    authService = AuthService(apiClient);
    userService = UserManagementService(apiClient);
    rbacService = RbacManagementService(apiClient);
    categoryService = CategoryManagementService(apiClient);
    productService = ProductManagementService(apiClient);
    orderService = OrderService(apiClient);
    inventoryService = InventoryService(apiClient);

    adminSession = const AuthSession(
      accessToken: 'dummy-token',
      tokenType: 'Bearer',
      expiresInSeconds: 86400,
      userId: '1',
      email: 'admin@joppe.vn',
      fullName: 'System Administrator',
      role: 'ROLE_ADMIN',
      permissions: ['USER_MANAGE', 'ROLE_MANAGE'],
    );
  });

  testWidgets('renders login screen when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
      ),
    );

    expect(find.text('Joppe Control Center'), findsOneWidget);
    expect(find.text('Sign in to manage backend, users & RBAC'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('renders dashboard shell and overview metrics when authenticated', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Joppe Admin Operations Center'), findsOneWidget);
    expect(find.text('System Users'), findsOneWidget);
    expect(find.text('Total Products'), findsOneWidget);
  });

  testWidgets('navigates to Users view and displays user list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap Users navigation item in navigation drawer (Vietnamese by default)
    final usersNavItem = find.text('Người dùng');
    expect(usersNavItem, findsOneWidget);
    await tester.tap(usersNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Verify Users view is visible
    expect(find.text('Thêm người dùng'), findsOneWidget);
    expect(find.text('System Administrator'), findsWidgets);
  });

  testWidgets('navigates to Categories view and displays category tree', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap Categories navigation item in navigation drawer
    final categoriesNavItem = find.text('Danh mục');
    expect(categoriesNavItem, findsOneWidget);
    await tester.tap(categoriesNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Verify Categories view is visible
    expect(find.text('Thêm danh mục'), findsOneWidget);
    expect(find.text('Laptops'), findsOneWidget);
    expect(find.text('/laptops'), findsOneWidget);
  });

  testWidgets('navigates to Products view and displays product list with multi-category tags', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap Products navigation item in navigation drawer
    final productsNavItem = find.text('Sản phẩm');
    expect(productsNavItem, findsOneWidget);
    await tester.tap(productsNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Verify Products view is visible
    expect(find.text('Thêm sản phẩm'), findsOneWidget);
    expect(find.text('ASUS ROG Strix G16'), findsOneWidget);
    expect(find.text('Laptops ★'), findsOneWidget);
    expect(find.text('Gaming'), findsOneWidget);
  });

  testWidgets('navigates to RBAC Matrix view and displays roles', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap RBAC Matrix navigation item in navigation drawer
    final rbacNavItem = find.text('Phân quyền RBAC');
    expect(rbacNavItem, findsOneWidget);
    await tester.tap(rbacNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify RBAC view is visible
    expect(find.text('Ma trận Vai trò & Quyền hạn'), findsOneWidget);
    expect(find.text('Thêm vai trò'), findsOneWidget);
    expect(find.text('ROLE_ADMIN'), findsWidgets);
  });

  testWidgets('navigates to Orders view and displays orders list', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final ordersNavItem = find.text('Đơn hàng');
    expect(ordersNavItem, findsOneWidget);
    await tester.tap(ordersNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Đơn hàng & Vận hành'), findsOneWidget);
    expect(find.text('ORD-20261022-TEST1'), findsOneWidget);
    expect(find.text('Nguyen Van A'), findsOneWidget);
  });

  testWidgets('navigates to POS Cashier view and displays cashier register and total to pay', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final posNavItem = find.text('Bán hàng (POS)');
    expect(posNavItem, findsOneWidget);
    await tester.tap(posNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify POS Cashier components
    expect(find.text('Hóa đơn thu ngân'), findsOneWidget);
    expect(find.text('TỔNG TIỀN PHẢI TRẢ'), findsOneWidget);
    expect(find.text('Thông tin khách mua'), findsOneWidget);
  });

  testWidgets('navigates to Settings view and displays settings options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final settingsNavItem = find.text('Cài đặt');
    expect(settingsNavItem, findsOneWidget);
    await tester.tap(settingsNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Tùy chỉnh ngôn ngữ và chế độ giao diện hệ thống'), findsOneWidget);
    expect(find.text('Ngôn ngữ hiển thị'), findsOneWidget);
    expect(find.text('Chế độ giao diện (Màu sắc)'), findsOneWidget);
  });

  testWidgets('switches sidebar language between Vietnamese and English via language selector in Settings view', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Default: Vietnamese in sidebar and title
    expect(find.text('Quản trị Joppe'), findsOneWidget);
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('Sản phẩm'), findsWidgets);
    expect(find.text('Người dùng'), findsWidgets);

    // Navigate to Settings view
    final settingsNavItem = find.text('Cài đặt');
    expect(settingsNavItem, findsOneWidget);
    await tester.tap(settingsNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('VI'), findsOneWidget);

    // Switch to English
    await tester.tap(find.text('VI'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // Now in English
    expect(find.text('Joppe Admin'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Products'), findsWidgets);
    expect(find.text('Users'), findsWidgets);
    expect(find.text('EN'), findsOneWidget);

    // Switch back to Vietnamese
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();

    expect(find.text('Quản trị Joppe'), findsOneWidget);
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('Sản phẩm'), findsWidgets);
    expect(find.text('Người dùng'), findsWidgets);
  });

  testWidgets('switches theme mode between system, dark, and light via theme mode selector in Settings view', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      JoppeDashboardApp(
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Navigate to Settings view
    final settingsNavItem = find.text('Cài đặt');
    expect(settingsNavItem, findsOneWidget);
    await tester.tap(settingsNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Default theme label is "Hệ thống"
    expect(find.text('Hệ thống'), findsOneWidget);

    // Tap theme selector to open menu
    await tester.tap(find.text('Hệ thống'));
    await tester.pumpAndSettle();

    // Select "Tối" (Dark Mode)
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    // Verify theme selector shows "Tối" and themeMode is dark
    expect(find.text('Tối'), findsOneWidget);
    final materialAppDark = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialAppDark.themeMode, ThemeMode.dark);

    // Switch to "Sáng" (Light Mode)
    await tester.tap(find.text('Tối'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sáng'));
    await tester.pumpAndSettle();

    expect(find.text('Sáng'), findsOneWidget);
    final materialAppLight = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialAppLight.themeMode, ThemeMode.light);
  });
}
