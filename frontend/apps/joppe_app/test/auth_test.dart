import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:joppe_core/joppe_core.dart' as core;
import 'package:joppe_app/src/models/user_account.dart';
import 'package:joppe_app/src/screens/auth_screen.dart';
import 'package:joppe_app/src/screens/profile_screen.dart';
import 'package:joppe_app/src/services/auth_service.dart';

void main() {
  group('joppe_core ApiClient & AuthService Unit Tests', () {
    test('Injects Bearer token into headers when token is set', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(jsonEncode({'status': 'ok'}), 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = core.ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
      apiClient.setToken('mock-jwt-token-xyz');
      expect(apiClient.hasToken, isTrue);
      expect(apiClient.token, 'mock-jwt-token-xyz');

      await apiClient.get('/api/v1/auth/me');
      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.headers['Authorization'], 'Bearer mock-jwt-token-xyz');
      expect(capturedRequest.url.path, '/api/v1/auth/me');
    });

    test('Resolves relative media URLs using baseUrl correctly', () {
      final apiClient = core.ApiClient(baseUrl: 'https://joppe.penguinlab.org');
      expect(apiClient.resolveMediaUrl(null), '');
      expect(apiClient.resolveMediaUrl(''), '');
      expect(
        apiClient.resolveMediaUrl('/uploads/products/gpu.webp'),
        'https://joppe.penguinlab.org/uploads/products/gpu.webp',
      );
      expect(
        apiClient.resolveMediaUrl('uploads/products/gpu.webp'),
        'https://joppe.penguinlab.org/uploads/products/gpu.webp',
      );
      expect(
        apiClient.resolveMediaUrl('https://images.unsplash.com/photo-1'),
        'https://images.unsplash.com/photo-1',
      );
    });

    test('POST /api/v1/auth/login and /register sets token in ApiClient', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/login') {
          return http.Response(
            jsonEncode({
              'accessToken': 'server-token-123',
              'tokenType': 'Bearer',
              'expiresInSeconds': 86400,
              'userId': 'u-1',
              'email': 'test@joppe.vn',
              'fullName': 'Test User',
              'role': 'ROLE_USER',
              'permissions': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/auth/register') {
          return http.Response(
            jsonEncode({
              'accessToken': 'server-token-456',
              'tokenType': 'Bearer',
              'expiresInSeconds': 86400,
              'userId': 'u-2',
              'email': 'an@joppe.vn',
              'fullName': 'An Tran',
              'role': 'ROLE_USER',
              'permissions': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final apiClient = core.ApiClient(baseUrl: 'http://localhost:8080', client: mockClient);
      final authService = core.AuthService(apiClient);

      final sessionLogin = await authService.login('test@joppe.vn', 'password123');
      expect(sessionLogin.accessToken, 'server-token-123');
      expect(apiClient.token, 'server-token-123');

      final sessionReg = await authService.register(
        fullName: 'An Tran',
        email: 'an@joppe.vn',
        password: '123',
      );
      expect(sessionReg.accessToken, 'server-token-456');
      expect(apiClient.token, 'server-token-456');
    });

    test('Logout clears token in ApiClient', () {
      final apiClient = core.ApiClient(baseUrl: 'http://localhost:8080');
      apiClient.setToken('valid-token');
      expect(apiClient.hasToken, isTrue);

      final authService = core.AuthService(apiClient);
      authService.logout();
      expect(apiClient.hasToken, isFalse);
      expect(apiClient.token, isNull);
    });
  });

  group('AuthService Unit Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
      authService.resetForTesting();
      authService.logout();
    });

    test('Initializes with demo accounts and unauthenticated state', () {
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
      expect(authService.allUsers, isNotEmpty);
      expect(authService.allUsers.any((u) => u.email == 'gamer@joppe.vn'), isTrue);
      expect(authService.allUsers.any((u) => u.email == 'admin@joppe.vn'), isTrue);
    });

    test('Fails login with empty credentials', () async {
      final resEmptyEmail = await authService.login(emailOrPhone: '', password: 'password');
      expect(resEmptyEmail.isSuccess, isFalse);
      expect(resEmptyEmail.message, contains('Vui lòng nhập email'));

      final resEmptyPass = await authService.login(emailOrPhone: 'gamer@joppe.vn', password: '');
      expect(resEmptyPass.isSuccess, isFalse);
      expect(resEmptyPass.message, contains('Vui lòng nhập mật khẩu'));
    });

    test('Fails login with non-existent user or wrong password', () async {
      final resUnknown = await authService.login(emailOrPhone: 'nonexistent@test.com', password: '123');
      expect(resUnknown.isSuccess, isFalse);
      expect(resUnknown.message.isNotEmpty, isTrue);

      final resWrongPass = await authService.login(emailOrPhone: 'gamer@joppe.vn', password: 'wrongpassword');
      expect(resWrongPass.isSuccess, isFalse);
      expect(resWrongPass.message, contains('Mật khẩu không chính xác'));
      expect(authService.isAuthenticated, isFalse);
    });

    test('Logs in successfully with email and phone number', () async {
      final resEmail = await authService.login(emailOrPhone: 'gamer@joppe.vn', password: '123456');
      expect(resEmail.isSuccess, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.email, 'gamer@joppe.vn');
      expect(authService.currentUser?.fullName, contains('Gamer'));

      await authService.logout();
      expect(authService.isAuthenticated, isFalse);

      final resPhone = await authService.login(emailOrPhone: '0988123456', password: '123456');
      expect(resPhone.isSuccess, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.phoneNumber, '0988123456');
    });

    test('Fails registration with invalid inputs', () async {
      final resEmptyName = await authService.register(
        fullName: '',
        email: 'test@joppe.vn',
        phoneNumber: '0912345678',
        password: 'password123',
      );
      expect(resEmptyName.isSuccess, isFalse);
      expect(resEmptyName.message, contains('Họ và tên không được để trống'));

      final resInvalidEmail = await authService.register(
        fullName: 'Nguyễn Văn A',
        email: 'invalid-email-address',
        phoneNumber: '0912345678',
        password: 'password123',
      );
      expect(resInvalidEmail.isSuccess, isFalse);
      expect(resInvalidEmail.message, contains('email không đúng định dạng'));

      final resShortPhone = await authService.register(
        fullName: 'Nguyễn Văn A',
        email: 'test@joppe.vn',
        phoneNumber: '123',
        password: 'password123',
      );
      expect(resShortPhone.isSuccess, isFalse);
      expect(resShortPhone.message, contains('Số điện thoại không hợp lệ'));

      final resShortPass = await authService.register(
        fullName: 'Nguyễn Văn A',
        email: 'test@joppe.vn',
        phoneNumber: '0912345678',
        password: '123',
      );
      expect(resShortPass.isSuccess, isFalse);
      expect(resShortPass.message, contains('Mật khẩu phải có ít nhất 6 ký tự'));
    });

    test('Fails registration when email or phone is already registered', () async {
      final resDupEmail = await authService.register(
        fullName: 'Trần Văn Trùng',
        email: 'gamer@joppe.vn',
        phoneNumber: '0977888999',
        password: 'password123',
      );
      expect(resDupEmail.isSuccess, isFalse);
      expect(resDupEmail.message, contains('Email này đã được đăng ký'));

      final resDupPhone = await authService.register(
        fullName: 'Trần Văn Trùng',
        email: 'unique@joppe.vn',
        phoneNumber: '0909999888',
        password: 'password123',
      );
      expect(resDupPhone.isSuccess, isFalse);
      expect(resDupPhone.message, contains('Số điện thoại này đã được sử dụng'));
    });

    test('Registers new user and awards bonus reward points', () async {
      final regRes = await authService.register(
        fullName: 'Võ Minh Chiến',
        email: 'chien.vo@joppe.vn',
        phoneNumber: '0933112233',
        password: 'securePassword123',
      );

      expect(regRes.isSuccess, isTrue);
      expect(regRes.message, contains('100 điểm thưởng'));
      expect(authService.isAuthenticated, isTrue);
      expect(authService.currentUser?.email, 'chien.vo@joppe.vn');
      expect(authService.currentUser?.rewardPoints, 100);

      await authService.logout();
      expect(authService.isAuthenticated, isFalse);

      final loginRes = await authService.login(
        emailOrPhone: 'chien.vo@joppe.vn',
        password: 'securePassword123',
      );
      expect(loginRes.isSuccess, isTrue);
      expect(authService.currentUser?.fullName, 'Võ Minh Chiến');
    });

    test('Resets password and allows login with new password', () async {
      final resetUnknown = await authService.resetPassword(
        email: 'nonexistent@joppe.vn',
        newPassword: 'newpassword123',
      );
      expect(resetUnknown.isSuccess, isFalse);
      expect(resetUnknown.message, contains('Không tìm thấy tài khoản'));

      final resetSuccess = await authService.resetPassword(
        email: 'gamer@joppe.vn',
        newPassword: 'newsecret123',
      );
      expect(resetSuccess.isSuccess, isTrue);

      final loginOld = await authService.login(emailOrPhone: 'gamer@joppe.vn', password: '123456');
      expect(loginOld.isSuccess, isFalse);

      final loginNew = await authService.login(emailOrPhone: 'gamer@joppe.vn', password: 'newsecret123');
      expect(loginNew.isSuccess, isTrue);
    });

    test('Updates profile when user is authenticated', () async {
      await authService.login(emailOrPhone: 'gamer@joppe.vn', password: '123456');
      expect(authService.isAuthenticated, isTrue);

      final updateRes = await authService.updateProfile(
        fullName: 'Nguyễn Thành Nam (Pro Gamer)',
        phoneNumber: '0999888777',
      );
      expect(updateRes.isSuccess, isTrue);
      expect(authService.currentUser?.fullName, 'Nguyễn Thành Nam (Pro Gamer)');
      expect(authService.currentUser?.phoneNumber, '0999888777');
    });

    test('UserAccount model serialization and copyWith', () {
      final user = UserAccount(
        id: 'user-test',
        fullName: 'Test Name',
        email: 'test@joppe.vn',
        phoneNumber: '0988777666',
        createdAt: DateTime(2025, 1, 1),
        role: 'VIP',
        rewardPoints: 300,
        isActive: true,
        token: 'token-jwt-1',
      );

      final json = user.toJson();
      expect(json['id'], 'user-test');
      expect(json['email'], 'test@joppe.vn');
      expect(json['token'], 'token-jwt-1');

      final deserialized = UserAccount.fromJson(json);
      expect(deserialized.id, user.id);
      expect(deserialized.fullName, user.fullName);
      expect(deserialized.token, 'token-jwt-1');

      final modified = user.copyWith(fullName: 'Updated Name', rewardPoints: 800);
      expect(modified.fullName, 'Updated Name');
      expect(modified.rewardPoints, 800);
      expect(modified.email, user.email);
    });
  });

  group('AuthScreen & ProfileScreen Widget Tests', () {
    setUp(() {
      AuthService().logout();
    });

    testWidgets('AuthScreen renders login form and handles input', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(initialIsLogin: true),
        ),
      );

      expect(find.text('JOPPE GAMING & WORKSTATION'), findsOneWidget);
      expect(find.text('ĐĂNG NHẬP HỆ THỐNG'), findsOneWidget);
      expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
      expect(find.text('ĐĂNG KÝ'), findsOneWidget);

      expect(find.text('Email hoặc Số điện thoại'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(find.text('Ghi nhớ đăng nhập'), findsOneWidget);
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('ĐĂNG NHẬP NGAY'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'gamer@joppe.vn');
      await tester.pumpAndSettle();
    });

    testWidgets('AuthScreen switches between login and register tabs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(initialIsLogin: true),
        ),
      );

      final registerTab = find.text('ĐĂNG KÝ');
      await tester.tap(registerTab);
      await tester.pumpAndSettle();

      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('TẠO TÀI KHOẢN NGAY'), findsOneWidget);
    });

    testWidgets('ProfileScreen shows unauthenticated state when logged out', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      AuthService().logout();

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      expect(find.text('CHƯA ĐĂNG NHẬP'), findsOneWidget);
      expect(find.text('ĐĂNG NHẬP / ĐĂNG KÝ'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders user details when logged in', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await AuthService().login(emailOrPhone: 'gamer@joppe.vn', password: '123456');

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nguyễn Thành Nam (Gamer)'), findsOneWidget);
      expect(find.text('gamer@joppe.vn'), findsOneWidget);
      expect(find.text('ĐĂNG XUẤT'), findsOneWidget);
    });
  });
}
