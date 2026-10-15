import '../api/api_client.dart';
import '../models/auth_session.dart';
import '../models/user_profile.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthSession> login(String email, String password) async {
    final response = await _apiClient.post('/api/v1/auth/login', {
      'email': email,
      'password': password,
    });
    final session = AuthSession.fromJson(response as Map<String, dynamic>);
    _apiClient.setToken(session.accessToken);
    return session;
  }

  Future<UserProfile> getCurrentProfile() async {
    final response = await _apiClient.get('/api/v1/auth/me');
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  void logout() {
    _apiClient.setToken(null);
  }
}
