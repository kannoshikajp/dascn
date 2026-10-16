import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_dashboard/src/widgets/profile_dialog.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  late MockClient mockClient;
  late ApiClient apiClient;
  late AuthService authService;
  late UserProfile testProfile;
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  setUp(() {
    testProfile = const UserProfile(
      id: 'user-uuid-1',
      email: 'admin@joppe.vn',
      fullName: 'System Administrator',
      phoneNumber: '0901234567',
      avatarUrl: null,
      role: 'ROLE_ADMIN',
      permissions: ['AUTH_ME', 'USER_MANAGE'],
      isActive: true,
    );

    mockClient = MockClient((request) async {
      if (request.method == 'PUT' && request.url.path == '/api/v1/auth/profile') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'id': 'user-uuid-1',
            'email': 'admin@joppe.vn',
            'fullName': body['fullName'],
            'phoneNumber': body['phoneNumber'],
            'avatarUrl': body['avatarUrl'],
            'role': 'ROLE_ADMIN',
            'permissions': ['AUTH_ME', 'USER_MANAGE'],
            'isActive': true,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.method == 'POST' && request.url.path == '/api/v1/auth/change-password') {
        return http.Response(
          jsonEncode({'success': true, 'message': 'Password changed successfully'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{"error":"not found"}', 404);
    });

    apiClient = ApiClient(client: mockClient);
    authService = AuthService(apiClient);
  });

  Widget createWidgetUnderTest({
    required UserProfile profile,
    ValueChanged<UserProfile>? onProfileUpdated,
  }) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: JoppeTheme.light(),
      home: Scaffold(
        body: ProfileDialog(
          profile: profile,
          authService: authService,
          onProfileUpdated: onProfileUpdated,
        ),
      ),
    );
  }

  testWidgets('renders profile details tab with current values', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest(profile: testProfile));
    await tester.pump();

    expect(find.text('System Administrator'), findsWidgets);
    expect(find.text('admin@joppe.vn'), findsWidgets);
    expect(find.text('ROLE_ADMIN'), findsWidgets);
    expect(find.text('Profile Details'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Save Profile'), findsOneWidget);
  });

  testWidgets('switches to security tab and displays password fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest(profile: testProfile));
    await tester.pump();

    // Tap Security tab
    await tester.tap(find.text('Security'));
    await tester.pumpAndSettle();

    expect(find.text('Change Account Password'), findsOneWidget);
    expect(find.text('Current Password *'), findsOneWidget);
    expect(find.text('New Password *'), findsOneWidget);
    expect(find.text('Confirm New Password *'), findsOneWidget);
    expect(find.text('Update Password'), findsOneWidget);
  });

  testWidgets('updates profile and triggers callback', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    UserProfile? updatedProfile;

    await tester.pumpWidget(
      createWidgetUnderTest(
        profile: testProfile,
        onProfileUpdated: (p) => updatedProfile = p,
      ),
    );
    await tester.pump();

    // Find and update full name
    final nameField = find.widgetWithText(TextFormField, 'Full Name *');
    await tester.enterText(nameField, 'Updated Admin Name');

    // Tap Save Profile
    final saveButton = find.text('Save Profile');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(updatedProfile, isNotNull);
    expect(updatedProfile!.fullName, 'Updated Admin Name');
    scaffoldMessengerKey.currentState?.clearSnackBars();
    await tester.pump();
  });

  testWidgets('changes password successfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest(profile: testProfile));
    await tester.pump();

    // Tap Security tab
    await tester.tap(find.text('Security'));
    await tester.pumpAndSettle();

    // Fill passwords
    final currentPass = find.widgetWithText(TextFormField, 'Current Password *');
    final newPass = find.widgetWithText(TextFormField, 'New Password *');
    final confirmPass = find.widgetWithText(TextFormField, 'Confirm New Password *');

    await tester.enterText(currentPass, 'OldPassword@123');
    await tester.enterText(newPass, 'NewPassword@123');
    await tester.enterText(confirmPass, 'NewPassword@123');

    final updateBtn = find.text('Update Password');
    await tester.ensureVisible(updateBtn);
    await tester.tap(updateBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Password changed successfully!'), findsOneWidget);
    scaffoldMessengerKey.currentState?.clearSnackBars();
    await tester.pump();
  });

  testWidgets('validates password mismatch on security tab', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest(profile: testProfile));
    await tester.pump();

    // Tap Security tab
    await tester.tap(find.text('Security'));
    await tester.pumpAndSettle();

    final currentPass = find.widgetWithText(TextFormField, 'Current Password *');
    final newPass = find.widgetWithText(TextFormField, 'New Password *');
    final confirmPass = find.widgetWithText(TextFormField, 'Confirm New Password *');

    await tester.enterText(currentPass, 'OldPassword@123');
    await tester.enterText(newPass, 'NewPassword@123');
    await tester.enterText(confirmPass, 'DifferentPassword');

    final updateBtn = find.text('Update Password');
    await tester.ensureVisible(updateBtn);
    await tester.tap(updateBtn);
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
