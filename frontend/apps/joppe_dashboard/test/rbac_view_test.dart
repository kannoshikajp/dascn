import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/localization/dashboard_localizations.dart';
import 'package:joppe_dashboard/src/views/rbac/molecules/edit_permissions_dialog.dart';
import 'package:joppe_dashboard/src/views/rbac/organisms/role_detail_panel.dart';
import 'package:joppe_dashboard/src/views/rbac/organisms/role_list_panel.dart';
import 'package:joppe_dashboard/src/views/rbac_view.dart';
import 'package:joppe_dashboard/src/views/users/molecules/user_notification_dialog.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late RbacManagementService rbacService;

  final sampleRoles = [
    {
      'id': 1,
      'roleName': 'ROLE_ADMIN',
      'description': 'System Administrator with full access',
      'permissions': [
        'AUTH_ME',
        'AUTH_CHANGE_PASSWORD',
        'CATALOG_READ',
        'CATALOG_WRITE',
        'ORDER_CREATE',
        'ORDER_MANAGE',
      ],
    },
    {
      'id': 2,
      'roleName': 'ROLE_STAFF',
      'description': 'Store Operations Staff',
      'permissions': [
        'CATALOG_READ',
        'ORDER_MANAGE',
      ],
    },
    {
      'id': 3,
      'roleName': 'ROLE_CUSTOMER',
      'description': 'Registered Customer',
      'permissions': [
        'AUTH_ME',
        'ORDER_CREATE',
      ],
    },
    {
      'id': 4,
      'roleName': 'ROLE_MODERATOR',
      'description': 'Custom Community Moderator',
      'permissions': [
        'CATALOG_READ',
      ],
    },
  ];

  final samplePermissions = [
    {'id': 1, 'permissionName': 'AUTH_ME', 'description': 'View profile'},
    {'id': 2, 'permissionName': 'AUTH_CHANGE_PASSWORD', 'description': 'Change password'},
    {'id': 3, 'permissionName': 'CATALOG_READ', 'description': 'Read catalog items'},
    {'id': 4, 'permissionName': 'CATALOG_WRITE', 'description': 'Modify catalog items'},
    {'id': 5, 'permissionName': 'ORDER_CREATE', 'description': 'Create new orders'},
    {'id': 6, 'permissionName': 'ORDER_MANAGE', 'description': 'Manage order status'},
  ];

  setUp(() {
    mockClient = MockClient((request) async {
      final path = request.url.path;

      if (path == '/api/v1/admin/roles') {
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 99,
              'roleName': body['roleName'],
              'description': body['description'],
              'permissions': body['permissions'] ?? [],
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(sampleRoles),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path == '/api/v1/admin/permissions') {
        return http.Response(
          jsonEncode(samplePermissions),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.startsWith('/api/v1/admin/roles/')) {
        if (path.endsWith('/permissions') && request.method == 'PUT') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              ...sampleRoles[0],
              'permissions': body['permissions'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
      }

      return http.Response('[]', 200, headers: {'content-type': 'application/json'});
    });

    apiClient = ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
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
        body: RbacView(rbacService: rbacService),
      ),
    );
  }

  testWidgets('renders RbacView with KPI cards, role list, and selected role details', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // KPI cards: Total Roles (4), System Roles (3), Custom Roles (1), Total Permissions (6)
    expect(find.text('Total Roles'), findsOneWidget);
    expect(find.text('System Roles'), findsOneWidget);
    expect(find.text('Custom Roles'), findsOneWidget);
    expect(find.text('Total Permissions'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('3'), findsWidgets);
    expect(find.text('1'), findsWidgets);
    expect(find.text('6'), findsWidgets);

    // Left role list
    expect(find.text('ROLE_ADMIN'), findsWidgets);
    expect(find.text('ROLE_STAFF'), findsOneWidget);
    expect(find.text('ROLE_CUSTOMER'), findsOneWidget);
    expect(find.text('ROLE_MODERATOR'), findsOneWidget);

    // Right detail panel (ROLE_ADMIN selected by default)
    expect(find.text('System Protected'), findsWidgets);
    expect(
      find.descendant(of: find.byType(RoleDetailPanel), matching: find.text('System Administrator with full access')),
      findsOneWidget,
    );
    expect(find.text('Granted Permissions (6)'), findsOneWidget);
    expect(find.text('Edit Permissions'), findsOneWidget);
  });

  testWidgets('switching selected role updates details and permission count', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap on ROLE_STAFF in left panel
    await tester.tap(find.descendant(of: find.byType(RoleListPanel), matching: find.text('ROLE_STAFF')));
    await tester.pump();

    // Verify right panel updated to ROLE_STAFF
    expect(find.text('Granted Permissions (2)'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(RoleDetailPanel), matching: find.text('Store Operations Staff')),
      findsOneWidget,
    );

    // Tap on ROLE_MODERATOR (custom role)
    await tester.tap(find.descendant(of: find.byType(RoleListPanel), matching: find.text('ROLE_MODERATOR')));
    await tester.pump();

    expect(find.text('Granted Permissions (1)'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(RoleDetailPanel), matching: find.text('Custom Community Moderator')),
      findsOneWidget,
    );
    expect(find.text('Custom role'), findsWidgets);
    // Custom role should display delete icon
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('searches and filters roles in left panel', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Enter search query 'staff'
    await tester.enterText(find.byType(TextField).first, 'staff');
    await tester.pump();

    expect(find.descendant(of: find.byType(RoleListPanel), matching: find.text('ROLE_STAFF')), findsOneWidget);
    expect(find.descendant(of: find.byType(RoleListPanel), matching: find.text('ROLE_ADMIN')), findsNothing);
    expect(find.descendant(of: find.byType(RoleListPanel), matching: find.text('ROLE_CUSTOMER')), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(find.descendant(of: find.byType(RoleListPanel), matching: find.text('ROLE_ADMIN')), findsOneWidget);
    expect(find.descendant(of: find.byType(RoleListPanel), matching: find.text('ROLE_STAFF')), findsOneWidget);
    expect(find.descendant(of: find.byType(RoleListPanel), matching: find.text('ROLE_CUSTOMER')), findsOneWidget);
  });

  testWidgets('opens Edit Permissions dialog with grouped pills and saves with UserNotificationDialog', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Edit Permissions button
    final editButton = find.widgetWithText(FilledButton, 'Edit Permissions');
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.byType(EditPermissionsDialog), findsOneWidget);
    expect(find.descendant(of: find.byType(EditPermissionsDialog), matching: find.text('Authentication')), findsOneWidget);
    expect(find.descendant(of: find.byType(EditPermissionsDialog), matching: find.text('Catalog & Products')), findsOneWidget);
    expect(find.descendant(of: find.byType(EditPermissionsDialog), matching: find.text('Orders & Tracking')), findsOneWidget);

    // FilterChip pills inside the dialog
    expect(find.widgetWithText(FilterChip, 'AUTH_ME'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'CATALOG_READ'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'ORDER_CREATE'), findsOneWidget);

    // Tap on CATALOG_WRITE pill to toggle
    final catalogWritePill = find.widgetWithText(FilterChip, 'CATALOG_WRITE');
    expect(catalogWritePill, findsOneWidget);
    await tester.tap(catalogWritePill);
    await tester.pump();

    // Tap Save Permissions button
    final saveButton = find.widgetWithText(FilledButton, 'Save Permissions');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify UserNotificationDialog appeared with success message
    expect(find.byType(UserNotificationDialog), findsOneWidget);
    expect(find.textContaining('Permissions updated for ROLE_ADMIN'), findsOneWidget);

    // Dismiss notification modal
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(UserNotificationDialog), findsNothing);
  });

  testWidgets('creates new role using CreateRoleDialog and surfaces UserNotificationDialog', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Add Role button in toolbar
    final addRoleBtn = find.widgetWithText(FilledButton, 'Add Role');
    expect(addRoleBtn, findsOneWidget);
    await tester.tap(addRoleBtn);
    await tester.pumpAndSettle();

    // Verify create dialog opened
    expect(find.text('Create New Role'), findsOneWidget);
    expect(find.text('Role Name (e.g. ROLE_MANAGER)'), findsOneWidget);

    // Tap submit without typing name to trigger validation
    final dialogAddBtn = find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(FilledButton, 'Add Role'),
    );
    await tester.tap(dialogAddBtn);
    await tester.pump();

    expect(find.text('Role name is required'), findsOneWidget);

    // Enter name without ROLE_
    await tester.enterText(find.widgetWithText(TextFormField, 'Role Name (e.g. ROLE_MANAGER)'), 'MANAGER');
    await tester.tap(dialogAddBtn);
    await tester.pump();
    expect(find.text('Must start with ROLE_'), findsOneWidget);

    // Enter valid name and select pills
    await tester.enterText(find.widgetWithText(TextFormField, 'Role Name (e.g. ROLE_MANAGER)'), 'ROLE_MANAGER');
    await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Store Manager');

    // Toggle a permission pill in create dialog
    final permPill = find.widgetWithText(FilterChip, 'CATALOG_READ');
    await tester.tap(permPill);
    await tester.pump();

    // Submit form
    await tester.tap(dialogAddBtn);
    await tester.pumpAndSettle();

    // Verify notification dialog surfaced
    expect(find.byType(UserNotificationDialog), findsOneWidget);
    expect(find.text('Role created successfully'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(UserNotificationDialog), findsNothing);
  });

  testWidgets('deletes custom role and surfaces UserNotificationDialog', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createSubject());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Select custom role ROLE_MODERATOR
    await tester.tap(find.text('ROLE_MODERATOR'));
    await tester.pump();

    // Tap delete button in header
    final deleteBtn = find.byIcon(Icons.delete_outline);
    expect(deleteBtn, findsOneWidget);
    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    // Verify confirmation modal
    expect(find.text('Delete Role'), findsWidgets);
    expect(find.text('Are you sure you want to delete role "ROLE_MODERATOR"?'), findsOneWidget);

    // Confirm deletion
    final confirmDelete = find.descendant(
      of: find.byType(Dialog),
      matching: find.widgetWithText(FilledButton, 'Delete Role'),
    );
    await tester.tap(confirmDelete);
    await tester.pumpAndSettle();

    // Verify notification dialog surfaced
    expect(find.byType(UserNotificationDialog), findsOneWidget);
    expect(find.text('Role deleted successfully'), findsOneWidget);

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

    expect(find.text('Tổng vai trò'), findsOneWidget);
    expect(find.text('Vai trò hệ thống'), findsOneWidget);
    expect(find.text('Vai trò tùy chỉnh'), findsOneWidget);
    expect(find.text('Tổng quyền hạn'), findsOneWidget);
    expect(find.text('Hệ thống bảo vệ'), findsWidgets);
    expect(find.text('Quyền hạn đã cấp (6)'), findsOneWidget);
    expect(find.text('Chỉnh sửa quyền hạn'), findsOneWidget);
    expect(find.text('Xác thực & Bảo mật'), findsOneWidget);
    expect(find.text('Danh mục & Sản phẩm'), findsOneWidget);
    expect(find.text('Đơn hàng & Theo dõi'), findsOneWidget);
  });
}
