import '../api/api_client.dart';
import '../models/category_item.dart';
import '../models/category_node.dart';

class CategoryManagementService {
  final ApiClient _apiClient;

  CategoryManagementService(this._apiClient);

  Future<List<CategoryItem>> listCategories({String? search, bool? isActive}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (isActive != null) params['isActive'] = isActive.toString();

    final response = await _apiClient.get('/api/v1/admin/categories', params);
    if (response is List) {
      return response
          .map((item) => CategoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<CategoryNode>> listCategoryTree({bool? isActive}) async {
    final params = <String, String>{};
    if (isActive != null) params['isActive'] = isActive.toString();

    final response = await _apiClient.get('/api/v1/admin/categories/tree', params);
    if (response is List) {
      return response
          .map((item) => CategoryNode.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<CategoryItem> getCategory(int id) async {
    final response = await _apiClient.get('/api/v1/admin/categories/$id');
    return CategoryItem.fromJson(response as Map<String, dynamic>);
  }

  Future<CategoryItem> createCategory({
    int? parentId,
    required String categoryName,
    String? slug,
    String? iconUrl,
    bool isActive = true,
  }) async {
    final body = {
      'parentId': parentId,
      'categoryName': categoryName,
      if (slug != null && slug.isNotEmpty) 'slug': slug,
      'iconUrl': iconUrl,
      'isActive': isActive,
    };
    final response = await _apiClient.post('/api/v1/admin/categories', body);
    return CategoryItem.fromJson(response as Map<String, dynamic>);
  }

  Future<CategoryItem> updateCategory({
    required int id,
    int? parentId,
    required String categoryName,
    String? slug,
    String? iconUrl,
    bool? isActive,
  }) async {
    final body = {
      'parentId': parentId,
      'categoryName': categoryName,
      if (slug != null && slug.isNotEmpty) 'slug': slug,
      'iconUrl': iconUrl,
      'isActive': isActive,
    };
    final response = await _apiClient.put('/api/v1/admin/categories/$id', body);
    return CategoryItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateStatus(int id, bool isActive) async {
    await _apiClient.patch('/api/v1/admin/categories/$id/status', {'isActive': isActive});
  }

  Future<void> deleteCategory(int id) async {
    await _apiClient.delete('/api/v1/admin/categories/$id');
  }
}
