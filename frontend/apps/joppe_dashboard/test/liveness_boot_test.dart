import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/main.dart';
import 'package:joppe_dashboard/src/screens/boot_loader_screen.dart';
import 'package:joppe_dashboard/src/screens/server_offline_screen.dart';

void main() {
  testWidgets('renders BootLoaderScreen with target host and spinner', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BootLoaderScreen(baseUrl: 'https://joppe.penguinlab.org'),
      ),
    );

    expect(find.text('Joppe Control Center'), findsOneWidget);
    expect(find.text('Verifying backend health on /live...'), findsOneWidget);
    expect(find.text('https://joppe.penguinlab.org'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders ServerOfflineScreen with uncloseable warning and retry action', (WidgetTester tester) async {
    bool retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ServerOfflineScreen(
          baseUrl: 'http://localhost:8080',
          errorMessage: 'Connection refused on port 8080',
          isRetrying: false,
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Server Unavailable'), findsOneWidget);
    expect(find.text('Backend service is not live or cannot be reached.'), findsOneWidget);
    expect(find.text('http://localhost:8080'), findsOneWidget);
    expect(find.text('http://localhost:8080/live'), findsOneWidget);
    expect(find.text('Connection refused on port 8080'), findsOneWidget);
    expect(
      find.text('This screen is locked and cannot be dismissed until /live is reachable.'),
      findsOneWidget,
    );
    expect(find.text('Retry Connection'), findsOneWidget);

    await tester.tap(find.text('Retry Connection'));
    expect(retried, isTrue);
  });

  testWidgets('shows offline screen when /live ping fails on dashboard startup', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/live') {
        return http.Response('{"status":"DOWN","message":"Database disconnected"}', 503);
      }
      return http.Response('[]', 200);
    });

    final apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    final authService = AuthService(apiClient);
    final userService = UserManagementService(apiClient);
    final rbacService = RbacManagementService(apiClient);
    final categoryService = CategoryManagementService(apiClient);
    final productService = ProductManagementService(apiClient);
    final orderService = OrderService(apiClient);
    final inventoryService = InventoryService(apiClient);

    await tester.pumpWidget(
      JoppeDashboardApp(
        apiClient: apiClient,
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        checkLivenessOnInit: true,
      ),
    );

    // Initial state: Boot loader
    expect(find.byType(BootLoaderScreen), findsOneWidget);

    // Let async check finish
    await tester.pumpAndSettle();

    // Barrier screen shown
    expect(find.byType(ServerOfflineScreen), findsOneWidget);
    expect(find.text('Server Unavailable'), findsOneWidget);
    expect(find.text('Database disconnected'), findsOneWidget);
  });

  testWidgets('transitions to login screen when /live ping succeeds', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/live') {
        return http.Response('{"status":"UP","message":"Healthy"}', 200, headers: {'content-type': 'application/json'});
      }
      return http.Response('[]', 200);
    });

    final apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    final authService = AuthService(apiClient);
    final userService = UserManagementService(apiClient);
    final rbacService = RbacManagementService(apiClient);
    final categoryService = CategoryManagementService(apiClient);
    final productService = ProductManagementService(apiClient);
    final orderService = OrderService(apiClient);
    final inventoryService = InventoryService(apiClient);

    await tester.pumpWidget(
      JoppeDashboardApp(
        apiClient: apiClient,
        authService: authService,
        userService: userService,
        rbacService: rbacService,
        categoryService: categoryService,
        productService: productService,
        orderService: orderService,
        inventoryService: inventoryService,
        checkLivenessOnInit: true,
      ),
    );

    await tester.pumpAndSettle();

    // Successfully transitioned to login screen
    expect(find.text('Joppe Control Center'), findsOneWidget);
    expect(find.text('Sign in to manage backend, users & RBAC'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
