import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/localization/dashboard_localizations.dart';
import 'package:joppe_dashboard/src/views/users/molecules/user_notification_dialog.dart';
import 'package:joppe_dashboard/src/views/users_view.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late UserManagementService userService;
  late RbacManagementService rbacService;

  final sampleRoles = [
    {
      'id': 1,
      'roleName': 'ROLE_ADMIN',
      'description': 'System Administrator',
      'permissions': ['USER_MANAGE', 'ROLE_MANAGE'],
    },
    {
      'id': 2,
      'roleName': 'ROLE_STAFF',
      'description': 'Store Operations Staff',
      'permissions': ['PRODUCT_READ', 'ORDER_MANAGE'],
    },
    {
      'id': 3,
      'roleName': 'ROLE_CUSTOMER',
      'description': 'Customer account',
      'permissions': ['PRODUCT_READ'],
    },
  ];

  final sampleUsers = [
    {
      'id': 'u-1',
      'email': 'alice@joppe.vn',
      'fullName': 'Alice Admin',
      'phoneNumber': '0901234567',
      'avatarUrl': null,
      'roleId': 1,
      'roleName': 'ROLE_ADMIN',
      'isActive': true,
      'createdAt': '2026-10-01T08:00:00Z',
    },
    {
      'id': 'u-2',
      'email': 'bob@joppe.vn',
      'fullName': 'Bob Staff',
      'phoneNumber': '0912345678',
      'avatarUrl': null,
      'roleId': 2,
      'roleName': 'ROLE_STAFF',
      'isActive': true,
      'createdAt': '2026-10-05T09:30:00Z',
    },
    {
      'id': 'u-3',
      'email': 'charlie@gmail.com',
      'fullName': 'Charlie Customer',
      'phoneNumber': null,
      'avatarUrl': null,
      'roleId': 3,
      'roleName': 'ROLE_CUSTOMER',
      'isActive': false,
      'createdAt': '2026-10-10T14:15:00Z',
    },
  ];

  setUp(() {
    mockClient = MockClient((request) async {
      if (request.url.path == '/api/v1/admin/roles') {
        return http.Response(
          jsonEncode(sampleRoles),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/api/v1/admin/users') {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'id': 'u-new',
              'email': 'newuser@joppe.vn',
              'fullName': 'New User',
              'phoneNumber': '0999888777',
              'avatarUrl': null,
              'roleId': 2,
              'roleName': 'ROLE_STAFF',
              'isActive': true,
              'createdAt': '2026-11-01T12:00:00Z',
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(sampleUsers),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.startsWith('/api/v1/admin/users/')) {
        if (request.url.path.endsWith('/status')) {
          return http.Response(
            jsonEncode({'success': true, 'message': 'Status updated'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'PUT') {
          return http.Response(
            jsonEncode({
              ...sampleUsers[0],
              'fullName': 'Alice Admin Updated',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'DELETE') {
          return http.Response(
            jsonEncode({'success': true, 'message': 'User deleted'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      }
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });

    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    userService = UserManagementService(apiClient);
    rbacService = RbacManagementService(apiClient);
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
        body: UsersView(
          userService: userService,
          rbacService: rbacService,
        ),
      ),
    );
  }

  testWidgets('renders UsersView with KPI metrics and user table', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify KPI cards
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('Active Users'), findsOneWidget);
    expect(find.text('Suspended Users'), findsOneWidget);
    expect(find.text('Staff & Admins'), findsOneWidget);

    // Verify values: 3 total, 2 active, 1 suspended, 2 staff & admins
    expect(find.text('3'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('1'), findsWidgets);

    // Verify users in table
    expect(find.text('Alice Admin'), findsOneWidget);
    expect(find.text('alice@joppe.vn'), findsOneWidget);
    expect(find.text('Bob Staff'), findsOneWidget);
    expect(find.text('bob@joppe.vn'), findsOneWidget);
    expect(find.text('Charlie Customer'), findsOneWidget);
    expect(find.text('charlie@gmail.com'), findsOneWidget);

    // Verify badges
    expect(find.text('Admin'), findsWidgets);
    expect(find.text('Staff'), findsWidgets);
    expect(find.text('Customer'), findsWidgets);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Suspended'), findsWidgets);
  });

  testWidgets('filters users by role pills', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Initially all 3 users are visible
    expect(find.text('Alice Admin'), findsOneWidget);
    expect(find.text('Bob Staff'), findsOneWidget);
    expect(find.text('Charlie Customer'), findsOneWidget);

    // Tap 'Admin' role pill
    final adminPill = find.widgetWithText(FilterChip, 'Admin');
    await tester.tap(adminPill);
    await tester.pump();

    expect(find.text('Alice Admin'), findsOneWidget);
    expect(find.text('Bob Staff'), findsNothing);
    expect(find.text('Charlie Customer'), findsNothing);

    // Tap 'Staff' role pill
    final staffPill = find.widgetWithText(FilterChip, 'Staff');
    await tester.tap(staffPill);
    await tester.pump();

    expect(find.text('Bob Staff'), findsOneWidget);
    expect(find.text('Alice Admin'), findsNothing);
    expect(find.text('Charlie Customer'), findsNothing);

    // Tap 'All Roles' pill
    final allRolesPill = find.widgetWithText(FilterChip, 'All Roles');
    await tester.tap(allRolesPill);
    await tester.pump();

    expect(find.text('Alice Admin'), findsOneWidget);
    expect(find.text('Bob Staff'), findsOneWidget);
    expect(find.text('Charlie Customer'), findsOneWidget);
  });

  testWidgets('filters users by status pills', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap 'Active Only' pill
    final activeOnlyPill = find.widgetWithText(FilterChip, 'Active Only');
    await tester.tap(activeOnlyPill);
    await tester.pump();

    expect(find.text('Alice Admin'), findsOneWidget);
    expect(find.text('Bob Staff'), findsOneWidget);
    expect(find.text('Charlie Customer'), findsNothing);

    // Tap 'Suspended Only' pill
    final suspendedOnlyPill = find.widgetWithText(FilterChip, 'Suspended Only');
    await tester.tap(suspendedOnlyPill);
    await tester.pump();

    expect(find.text('Charlie Customer'), findsOneWidget);
    expect(find.text('Alice Admin'), findsNothing);
    expect(find.text('Bob Staff'), findsNothing);
  });

  testWidgets('filters users via search input and clear button', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Search 'bob@joppe'
    await tester.enterText(find.byType(TextField).first, 'bob@joppe');
    await tester.pump();

    expect(find.text('Bob Staff'), findsOneWidget);
    expect(find.text('Alice Admin'), findsNothing);
    expect(find.text('Charlie Customer'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.text('Alice Admin'), findsOneWidget);
    expect(find.text('Bob Staff'), findsOneWidget);
    expect(find.text('Charlie Customer'), findsOneWidget);
  });

  testWidgets('opens Add User dialog and validates required fields', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap 'Add User' button
    final addUserButton = find.widgetWithText(FilledButton, 'Add User');
    expect(addUserButton, findsOneWidget);
    await tester.tap(addUserButton);
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.text('Role')),
      findsOneWidget,
    );

    // Tap submit without filling fields to trigger validation
    final dialogSubmit = find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(FilledButton, 'Add User'),
    );
    await tester.tap(dialogSubmit);
    await tester.pump();

    expect(find.text('Valid email required'), findsOneWidget);
    expect(find.text('Min 6 characters required'), findsOneWidget);
    expect(find.text('Full name required'), findsOneWidget);

    // Close dialog
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  });

  testWidgets('displays error when attempting to deactivate last active admin account', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Mock API returning 403 on deactivating u-1 (Alice Admin)
    mockClient = MockClient((request) async {
      if (request.url.path == '/api/v1/admin/roles') {
        return http.Response(jsonEncode(sampleRoles), 200, headers: {'content-type': 'application/json'});
      }
      if (request.url.path == '/api/v1/admin/users') {
        return http.Response(jsonEncode(sampleUsers), 200, headers: {'content-type': 'application/json'});
      }
      if (request.url.path == '/api/v1/admin/users/u-1/status') {
        return http.Response(
          jsonEncode({
            'status': 403,
            'error': 'Forbidden',
            'message': 'At least one active administrator account is required.'
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });
    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
    userService = UserManagementService(apiClient);
    rbacService = RbacManagementService(apiClient);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Open action menu on Alice Admin (first menu)
    final menuButtons = find.byIcon(Icons.more_vert_rounded);
    expect(menuButtons, findsWidgets);

    await tester.tap(menuButtons.first);
    await tester.pumpAndSettle();

    // Tap 'Suspend Account' item
    final suspendItem = find.text('Suspend Account');
    expect(suspendItem, findsOneWidget);
    await tester.tap(suspendItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify center screen notification modal surfaced
    expect(find.byType(UserNotificationDialog), findsOneWidget);
    expect(find.textContaining('At least one active administrator account is required'), findsOneWidget);

    // Close center notification modal
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(UserNotificationDialog), findsNothing);
  });

  testWidgets('renders properly with Vietnamese locale', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject(locale: const Locale('vi')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tổng người dùng'), findsOneWidget);
    expect(find.text('Đang hoạt động'), findsWidgets);
    expect(find.text('Đã tạm khóa'), findsOneWidget);
    expect(find.text('Nhân sự & Quản trị'), findsOneWidget);
    expect(find.text('Thêm người dùng'), findsOneWidget);
    expect(find.text('Người dùng'), findsOneWidget);
    expect(find.text('Vai trò'), findsWidgets);
    expect(find.text('Số điện thoại'), findsOneWidget);
    expect(find.text('Trạng thái'), findsOneWidget);
    expect(find.text('Ngày tham gia'), findsOneWidget);
    expect(find.text('Quản trị viên'), findsWidgets);
    expect(find.text('Nhân viên'), findsWidgets);
    expect(find.text('Khách hàng'), findsWidgets);
  });
}
