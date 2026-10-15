import '../api/api_client.dart';
import '../models/permission_item.dart';
import '../models/role_item.dart';

class RbacManagementService {
  final ApiClient _apiClient;

  RbacManagementService(this._apiClient);

  Future<List<RoleItem>> listRoles() async {
    final response = await _apiClient.get('/api/v1/admin/roles');
    if (response is List) {
      return response
          .map((item) => RoleItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<RoleItem> getRole(int id) async {
    final response = await _apiClient.get('/api/v1/admin/roles/$id');
    return RoleItem.fromJson(response as Map<String, dynamic>);
  }

  Future<RoleItem> createRole({
    required String roleName,
    String? description,
    required List<String> permissions,
  }) async {
    final body = {
      'roleName': roleName,
      'description': description,
      'permissions': permissions,
    };
    final response = await _apiClient.post('/api/v1/admin/roles', body);
    return RoleItem.fromJson(response as Map<String, dynamic>);
  }

  Future<RoleItem> updateRolePermissions({
    required int id,
    required List<String> permissions,
  }) async {
    final body = {
      'permissions': permissions,
    };
    final response = await _apiClient.put('/api/v1/admin/roles/$id/permissions', body);
    return RoleItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteRole(int id) async {
    await _apiClient.delete('/api/v1/admin/roles/$id');
  }

  Future<List<PermissionItem>> listPermissions() async {
    final response = await _apiClient.get('/api/v1/admin/permissions');
    if (response is List) {
      return response
          .map((item) => PermissionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
