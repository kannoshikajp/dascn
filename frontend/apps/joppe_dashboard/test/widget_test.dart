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
  late AuthSession adminSession;

  setUp(() {
    mockClient = MockClient((request) async {
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
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });

    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    authService = AuthService(apiClient);
    userService = UserManagementService(apiClient);
    rbacService = RbacManagementService(apiClient);
    categoryService = CategoryManagementService(apiClient);
    productService = ProductManagementService(apiClient);

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
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Joppe Admin'), findsOneWidget);
    expect(find.text('admin@joppe.vn'), findsOneWidget);
    expect(find.text('ROLE_ADMIN'), findsOneWidget);
    expect(find.text('Joppe Admin Operations Center'), findsOneWidget);
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('Active Accounts'), findsOneWidget);
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
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap Users navigation item in navigation drawer
    final usersNavItem = find.text('Users');
    expect(usersNavItem, findsOneWidget);
    await tester.tap(usersNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Verify Users view is visible
    expect(find.text('Add User'), findsOneWidget);
    expect(find.text('System Administrator'), findsOneWidget);
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
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap Categories navigation item in navigation drawer
    final categoriesNavItem = find.text('Categories');
    expect(categoriesNavItem, findsOneWidget);
    await tester.tap(categoriesNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Verify Categories view is visible
    expect(find.text('Add Category'), findsOneWidget);
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
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap Products navigation item in navigation drawer
    final productsNavItem = find.text('Products');
    expect(productsNavItem, findsOneWidget);
    await tester.tap(productsNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    // Verify Products view is visible
    expect(find.text('Add Product'), findsOneWidget);
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
        initialSession: adminSession,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Tap RBAC Matrix navigation item in navigation drawer
    final rbacNavItem = find.text('RBAC Matrix');
    expect(rbacNavItem, findsOneWidget);
    await tester.tap(rbacNavItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify RBAC view is visible
    expect(find.text('Roles & Permissions Matrix'), findsOneWidget);
    expect(find.text('Add Role'), findsOneWidget);
    expect(find.text('Configure Permissions'), findsOneWidget);
    expect(find.text('USER_MANAGE'), findsOneWidget);
  });
}
