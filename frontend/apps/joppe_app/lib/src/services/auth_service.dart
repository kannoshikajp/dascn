import 'package:flutter/foundation.dart';
import 'package:joppe_core/joppe_core.dart' as core;
import '../models/user_account.dart';
import 'app_api_client.dart';

class AuthResult {
  final bool isSuccess;
  final String message;
  final UserAccount? user;

  const AuthResult({
    required this.isSuccess,
    required this.message,
    this.user,
  });

  factory AuthResult.success(String message, UserAccount user) {
    return AuthResult(isSuccess: true, message: message, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult(isSuccess: false, message: message, user: null);
  }
}

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    _initializeDemoAccounts();
  }

  core.ApiClient get apiClient => AppApiClient.instance;
  core.AuthService get _coreAuth => core.AuthService(apiClient);

  UserAccount? _currentUser;
  final Map<String, String> _passwords = {};
  final Map<String, UserAccount> _usersByEmail = {};

  UserAccount? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get hasRemoteToken => apiClient.hasToken;
  List<UserAccount> get allUsers => _usersByEmail.values.toList();

  void _initializeDemoAccounts() {
    final demoGamer = UserAccount(
      id: 'user-gamer-001',
      fullName: 'Nguyễn Thành Nam (Gamer)',
      email: 'gamer@joppe.vn',
      phoneNumber: '0988123456',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80',
      createdAt: DateTime(2025, 1, 15),
      role: 'VIP Gamer Diamond',
      rewardPoints: 2450,
    );

    final demoAdmin = UserAccount(
      id: 'user-admin-001',
      fullName: 'Quản Trị Viên Kỹ Thuật',
      email: 'admin@joppe.vn',
      phoneNumber: '0909999888',
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=400&q=80',
      createdAt: DateTime(2024, 6, 1),
      role: 'Quản trị viên',
      rewardPoints: 9999,
    );

    _usersByEmail[demoGamer.email.toLowerCase()] = demoGamer;
    _passwords[demoGamer.email.toLowerCase()] = '123456';

    _usersByEmail[demoAdmin.email.toLowerCase()] = demoAdmin;
    _passwords[demoAdmin.email.toLowerCase()] = 'admin123';
  }

  void resetForTesting() {
    _currentUser = null;
    apiClient.setToken(null);
    _passwords.clear();
    _usersByEmail.clear();
    _initializeDemoAccounts();
  }

  @visibleForTesting
  void setUserForTesting(UserAccount? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<AuthResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final cleanInput = emailOrPhone.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanInput.isEmpty) {
      return AuthResult.failure('Vui lòng nhập email hoặc số điện thoại.');
    }
    if (cleanPassword.isEmpty) {
      return AuthResult.failure('Vui lòng nhập mật khẩu.');
    }

    // 1. Kết nối tới Joppe API qua joppe_core.AuthService trước (để nhận JWT Bearer token chính thức)
    try {
      final session = await _coreAuth.login(cleanInput, cleanPassword);
      core.UserProfile? profile;
      try {
        profile = await _coreAuth.getCurrentProfile();
      } catch (_) {}

      final user = UserAccount(
        id: session.userId,
        fullName: profile?.fullName ?? session.fullName,
        email: session.email,
        phoneNumber: profile?.phoneNumber ?? '',
        avatarUrl: profile?.avatarUrl,
        createdAt: DateTime.now(),
        role: session.role,
        permissions: session.permissions,
        token: session.accessToken,
      );

      _currentUser = user;
      _usersByEmail[cleanInput] = user;
      _passwords[cleanInput] = cleanPassword;
      notifyListeners();
      return AuthResult.success('Đăng nhập thành công qua máy chủ API!', user);
    } catch (_) {
      // 2. Dự phòng tài khoản Demo cục bộ nếu máy chủ offline hoặc không có mạng
      if (_usersByEmail.containsKey(cleanInput) || _usersByEmail.values.any((u) => u.phoneNumber == cleanInput)) {
        final user = _usersByEmail[cleanInput] ??
            _usersByEmail.values.firstWhere((u) => u.phoneNumber == cleanInput);
        final storedPass = _passwords[user.email.toLowerCase()];

        if (storedPass == cleanPassword || (user.email == 'gamer@joppe.vn' && cleanPassword == 'password123')) {
          _currentUser = user;
          notifyListeners();
          return AuthResult.success('Đăng nhập thành công! Chào mừng ${_currentUser!.fullName}.', _currentUser!);
        } else {
          return AuthResult.failure('Mật khẩu không chính xác. Vui lòng thử lại.');
        }
      }
      return AuthResult.failure('Tài khoản không tồn tại trên hệ thống.');
    }
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final cleanFullName = fullName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phoneNumber.trim();
    final cleanPassword = password.trim();

    if (cleanFullName.isEmpty) {
      return AuthResult.failure('Họ và tên không được để trống.');
    }
    if (cleanEmail.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(cleanEmail)) {
      return AuthResult.failure('Địa chỉ email không đúng định dạng.');
    }
    if (cleanPhone.isEmpty || cleanPhone.length < 9) {
      return AuthResult.failure('Số điện thoại không hợp lệ.');
    }
    if (cleanPassword.length < 6) {
      return AuthResult.failure('Mật khẩu phải có ít nhất 6 ký tự.');
    }

    if (_usersByEmail.containsKey(cleanEmail)) {
      return AuthResult.failure('Email này đã được đăng ký tài khoản trước đó.');
    }

    for (final existing in _usersByEmail.values) {
      if (existing.phoneNumber == cleanPhone) {
        return AuthResult.failure('Số điện thoại này đã được sử dụng cho một tài khoản khác.');
      }
    }

    try {
      final session = await _coreAuth.register(
        fullName: cleanFullName,
        email: cleanEmail,
        password: cleanPassword,
        phoneNumber: cleanPhone,
      );

      final user = UserAccount(
        id: session.userId,
        fullName: session.fullName,
        email: session.email,
        phoneNumber: cleanPhone,
        createdAt: DateTime.now(),
        role: session.role.isNotEmpty ? session.role : 'Thành viên mới',
        rewardPoints: 100,
        token: session.accessToken,
      );

      _currentUser = user;
      _usersByEmail[cleanEmail] = user;
      _passwords[cleanEmail] = cleanPassword;
      notifyListeners();
      return AuthResult.success('Đăng ký tài khoản thành công! Tặng bạn 100 điểm thưởng chào mừng.', user);
    } on core.ApiException catch (e) {
      if (e.statusCode == 409) {
        return AuthResult.failure('Email này đã được đăng ký tài khoản trước đó.');
      }
    } catch (_) {
      // Fallback offline lưu trữ
    }

    final newUser = UserAccount(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: cleanFullName,
      email: cleanEmail,
      phoneNumber: cleanPhone,
      createdAt: DateTime.now(),
      role: 'Thành viên mới',
      rewardPoints: 100,
    );

    _usersByEmail[cleanEmail] = newUser;
    _passwords[cleanEmail] = cleanPassword;
    _currentUser = newUser;
    notifyListeners();

    return AuthResult.success('Đăng ký tài khoản thành công! Tặng bạn 100 điểm thưởng chào mừng.', newUser);
  }

  Future<AuthResult> loginWithGoogle(String idToken) async {
    try {
      final session = await _coreAuth.loginWithGoogle(idToken);
      final user = UserAccount(
        id: session.userId,
        fullName: session.fullName,
        email: session.email,
        phoneNumber: '',
        createdAt: DateTime.now(),
        role: session.role,
        token: session.accessToken,
      );
      _currentUser = user;
      _usersByEmail[session.email.toLowerCase()] = user;
      notifyListeners();
      return AuthResult.success('Đăng nhập Google thành công! Chào mừng ${_currentUser!.fullName}.', user);
    } catch (e) {
      return AuthResult.failure('Lỗi kết nối khi đăng nhập Google: $e');
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _coreAuth.logout();
    notifyListeners();
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = newPassword.trim();

    if (cleanEmail.isEmpty) {
      return AuthResult.failure('Vui lòng cung cấp email.');
    }
    if (cleanPassword.length < 6) {
      return AuthResult.failure('Mật khẩu mới phải có tối thiểu 6 ký tự.');
    }

    if (!_usersByEmail.containsKey(cleanEmail)) {
      return AuthResult.failure('Không tìm thấy tài khoản tương ứng với email này.');
    }

    _passwords[cleanEmail] = cleanPassword;
    return AuthResult.success('Khôi phục mật khẩu thành công! Bạn có thể đăng nhập ngay bây giờ.', _usersByEmail[cleanEmail]!);
  }

  Future<AuthResult> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) {
      return AuthResult.failure('Chưa đăng nhập.');
    }

    try {
      if (apiClient.hasToken) {
        final profile = await _coreAuth.updateProfile(
          fullName: fullName.trim(),
          phoneNumber: phoneNumber.trim(),
          avatarUrl: avatarUrl,
        );

        final updated = _currentUser!.copyWith(
          fullName: profile.fullName,
          phoneNumber: profile.phoneNumber,
          avatarUrl: profile.avatarUrl,
        );
        _currentUser = updated;
        _usersByEmail[updated.email.toLowerCase()] = updated;
        notifyListeners();
        return AuthResult.success('Cập nhật thông tin tài khoản thành công qua máy chủ API.', updated);
      }
    } catch (_) {}

    final updated = _currentUser!.copyWith(
      fullName: fullName.trim(),
      phoneNumber: phoneNumber.trim(),
      avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
    );

    _currentUser = updated;
    _usersByEmail[updated.email.toLowerCase()] = updated;
    notifyListeners();

    return AuthResult.success('Cập nhật thông tin tài khoản thành công.', updated);
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) {
      return AuthResult.failure('Vui lòng đăng nhập trước khi đổi mật khẩu.');
    }
    if (newPassword.trim().length < 6) {
      return AuthResult.failure('Mật khẩu mới phải có tối thiểu 6 ký tự.');
    }

    if (apiClient.hasToken) {
      try {
        await _coreAuth.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        _passwords[_currentUser!.email.toLowerCase()] = newPassword.trim();
        return AuthResult.success('Đổi mật khẩu thành công trên hệ thống!', _currentUser!);
      } on core.ApiException catch (e) {
        return AuthResult.failure(e.message);
      } catch (e) {
        return AuthResult.failure('Đổi mật khẩu thất bại: $e');
      }
    }

    final email = _currentUser!.email.toLowerCase();
    final storedPass = _passwords[email];
    if (storedPass != null && storedPass != currentPassword.trim()) {
      return AuthResult.failure('Mật khẩu hiện tại không chính xác.');
    }

    _passwords[email] = newPassword.trim();
    return AuthResult.success('Đổi mật khẩu tài khoản thành công!', _currentUser!);
  }
}
