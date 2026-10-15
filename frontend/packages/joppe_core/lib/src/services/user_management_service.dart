import '../api/api_client.dart';
import '../models/user_summary.dart';

class UserManagementService {
  final ApiClient _apiClient;

  UserManagementService(this._apiClient);

  Future<List<UserSummary>> listUsers({
    String? search,
    int? roleId,
    bool? isActive,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (roleId != null) params['roleId'] = roleId.toString();
    if (isActive != null) params['isActive'] = isActive.toString();

    final response = await _apiClient.get('/api/v1/admin/users', params);
    if (response is List) {
      return response
          .map((item) => UserSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<UserSummary> createUser({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    required int roleId,
  }) async {
    final body = {
      'email': email,
      'password': password,
      'fullName': fullName,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
      'roleId': roleId,
    };
    final response = await _apiClient.post('/api/v1/admin/users', body);
    return UserSummary.fromJson(response as Map<String, dynamic>);
  }

  Future<UserSummary> updateUser({
    required String id,
    required String fullName,
    String? phoneNumber,
    String? avatarUrl,
    required int roleId,
    required bool isActive,
  }) async {
    final body = {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'roleId': roleId,
      'isActive': isActive,
    };
    final response = await _apiClient.put('/api/v1/admin/users/$id', body);
    return UserSummary.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateStatus(String id, bool isActive) async {
    await _apiClient.patch('/api/v1/admin/users/$id/status', {'isActive': isActive});
  }

  Future<void> deleteUser(String id) async {
    await _apiClient.delete('/api/v1/admin/users/$id');
  }
}
