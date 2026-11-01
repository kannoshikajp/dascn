import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/category_item.dart';
import '../models/category_node.dart';
import '../models/product_item.dart';

class StoreCatalogService {
  final ApiClient _client;

  StoreCatalogService(this._client);

  Future<List<ProductItem>> getProducts({
    String? search,
    int? categoryId,
    int? brandId,
  }) async {
    final params = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (categoryId != null) {
      params['categoryId'] = categoryId.toString();
    }
    if (brandId != null) {
      params['brandId'] = brandId.toString();
    }

    final response = await _client.get(ApiConstants.products, params);
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map((item) => ProductItem.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<ProductItem> getProductById(String id) async {
    final response = await _client.get('${ApiConstants.products}/$id');
    return ProductItem.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductItem> getProductBySlug(String slug) async {
    final response = await _client.get('${ApiConstants.products}/slug/$slug');
    return ProductItem.fromJson(response as Map<String, dynamic>);
  }

  Future<List<CategoryNode>> getCategoryTree() async {
    final response = await _client.get(ApiConstants.categoriesTree);
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map((item) => CategoryNode.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<CategoryItem> getCategoryById(int id) async {
    final response = await _client.get('${ApiConstants.categories}/$id');
    return CategoryItem.fromJson(response as Map<String, dynamic>);
  }

  Future<CategoryItem> getCategoryBySlug(String slug) async {
    final response = await _client.get('${ApiConstants.categories}/slug/$slug');
    return CategoryItem.fromJson(response as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getRawCategoryTree() async {
    final response = await _client.get(ApiConstants.categoriesTree);
    if (response is List) {
      return response
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getRawProducts({
    String? search,
    int? categoryId,
    int? brandId,
  }) async {
    final params = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (categoryId != null) {
      params['categoryId'] = categoryId.toString();
    }
    if (brandId != null) {
      params['brandId'] = brandId.toString();
    }

    final response = await _client.get(ApiConstants.products, params);
    if (response is List) {
      return response
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }
}
