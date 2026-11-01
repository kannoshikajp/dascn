import '../api/api_client.dart';
import '../models/auth_session.dart';
import '../models/user_profile.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  ApiClient get client => _apiClient;

  Future<AuthSession> login(String email, String password) async {
    final response = await _apiClient.post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
    final session = AuthSession.fromJson(response as Map<String, dynamic>);
    _apiClient.setToken(session.accessToken);
    return session;
  }

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'password': password,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
    };
    final response = await _apiClient.post('/api/v1/auth/register', body);
    final session = AuthSession.fromJson(response as Map<String, dynamic>);
    _apiClient.setToken(session.accessToken);
    return session;
  }

  Future<AuthSession> loginWithGoogle(String idToken) async {
    final response = await _apiClient.post('/api/v1/auth/google', {
      'idToken': idToken,
    });
    final session = AuthSession.fromJson(response as Map<String, dynamic>);
    _apiClient.setToken(session.accessToken);
    return session;
  }

  Future<UserProfile> getCurrentProfile() async {
    final response = await _apiClient.get('/api/v1/auth/me');
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    required String fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{
      'fullName': fullName,
    };
    if (phoneNumber != null) {
      payload['phoneNumber'] = phoneNumber;
    }
    if (avatarUrl != null) {
      payload['avatarUrl'] = avatarUrl;
    }
    final response = await _apiClient.put('/api/v1/auth/profile', payload);
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.post('/api/v1/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  void logout() {
    _apiClient.setToken(null);
  }
}
