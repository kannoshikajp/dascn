import '../api/api_client.dart';
import '../models/product_item.dart';
import '../models/product_variant_summary.dart';

class ProductManagementService {
  final ApiClient _apiClient;

  ProductManagementService(this._apiClient);

  Future<List<ProductItem>> listProducts({
    String? search,
    int? categoryId,
    int? brandId,
    bool? isActive,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['categoryId'] = categoryId.toString();
    if (brandId != null) params['brandId'] = brandId.toString();
    if (isActive != null) params['isActive'] = isActive.toString();

    final response = await _apiClient.get('/api/v1/admin/products', params);
    if (response is List) {
      return response
          .map((item) => ProductItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<String> exportProductsCsv({
    String? search,
    int? categoryId,
    int? brandId,
    bool? isActive,
  }) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['categoryId'] = categoryId.toString();
    if (brandId != null) params['brandId'] = brandId.toString();
    if (isActive != null) params['isActive'] = isActive.toString();

    return await _apiClient.getRaw('/api/v1/admin/products/export', params);
  }

  Future<ProductItem> getProduct(String id) async {
    final response = await _apiClient.get('/api/v1/admin/products/$id');
    return ProductItem.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductItem> createProduct({
    required String productName,
    required String sku,
    String? parentSku,
    String? slug,
    int? brandId,
    List<int>? categoryIds,
    int? primaryCategoryId,
    bool isActive = true,
    String? versionCode,
    String? variantCode,
    String? thumbnailUrl,
    String? description,
    double? listPrice,
    double? salePrice,
    int? stockQuantity,
  }) async {
    final body = {
      'productName': productName,
      'sku': sku,
      if (parentSku != null && parentSku.isNotEmpty) 'parentSku': parentSku,
      if (slug != null && slug.isNotEmpty) 'slug': slug,
      'brandId': brandId,
      'categoryIds': ?categoryIds,
      'primaryCategoryId': ?primaryCategoryId,
      'isActive': isActive,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (description != null) 'description': description,
      'listPrice': ?listPrice,
      'salePrice': ?salePrice,
      'stockQuantity': ?stockQuantity,
    };

    final response = await _apiClient.post('/api/v1/admin/products', body);
    return ProductItem.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductItem> updateProduct({
    required String id,
    required String productName,
    String? sku,
    String? parentSku,
    String? versionCode,
    String? slug,
    int? brandId,
    List<int>? categoryIds,
    int? primaryCategoryId,
    bool? isActive,
    double? listPrice,
    double? salePrice,
    int? stockQuantity,
    String? thumbnailUrl,
    String? description,
  }) async {
    final body = {
      'productName': productName,
      if (sku != null && sku.isNotEmpty) 'sku': sku,
      if (parentSku != null && parentSku.isNotEmpty) 'parentSku': parentSku,
      if (slug != null && slug.isNotEmpty) 'slug': slug,
      'brandId': brandId,
      'categoryIds': ?categoryIds,
      'primaryCategoryId': ?primaryCategoryId,
      if (isActive != null) 'isActive': isActive,
      'listPrice': ?listPrice,
      'salePrice': ?salePrice,
      'stockQuantity': ?stockQuantity,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (description != null) 'description': description,
    };

    final response = await _apiClient.put('/api/v1/admin/products/$id', body);
    return ProductItem.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updateStatus(String id, bool isActive) async {
    await _apiClient.patch('/api/v1/admin/products/$id/status', {'isActive': isActive});
  }

  Future<void> deleteProduct(String id) async {
    await _apiClient.delete('/api/v1/admin/products/$id');
  }

  // =========================================================================
  // Variant Management
  // =========================================================================

  Future<List<ProductVariantSummary>> listVariants(String productId) async {
    final response = await _apiClient.get('/api/v1/admin/products/$productId/variants');
    if (response is List) {
      return response
          .map((item) => ProductVariantSummary.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ProductVariantSummary> createVariant(
    String productId, {
    required String sku,
    String? versionCode,
    String? variantCode,
    required String variantName,
    String? thumbnailUrl,
    String? description,
    List<String>? mediaIds,
    String? attributes,
    double? listPrice,
    double? salePrice,
    int? quantityOnHand,
    int? reorderLevel,
    double? weightGram,
    bool isActive = true,
  }) async {
    final body = {
      'sku': sku,
      if (versionCode != null) 'versionCode': versionCode,
      if (variantCode != null) 'variantCode': variantCode,
      'variantName': variantName,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'mediaIds': ?mediaIds,
      'attributes': attributes,
      'listPrice': ?listPrice,
      'salePrice': ?salePrice,
      'quantityOnHand': ?quantityOnHand,
      'reorderLevel': ?reorderLevel,
      'weightGram': ?weightGram,
      'isActive': isActive,
    };
    final response = await _apiClient.post('/api/v1/admin/products/$productId/variants', body);
    return ProductVariantSummary.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductVariantSummary> updateVariant(
    String productId,
    String variantId, {
    required String sku,
    String? versionCode,
    String? variantCode,
    required String variantName,
    String? thumbnailUrl,
    String? description,
    List<String>? mediaIds,
    String? attributes,
    double? listPrice,
    double? salePrice,
    int? quantityOnHand,
    int? reorderLevel,
    double? weightGram,
    bool? isActive,
  }) async {
    final body = {
      'sku': sku,
      if (versionCode != null) 'versionCode': versionCode,
      if (variantCode != null) 'variantCode': variantCode,
      'variantName': variantName,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'mediaIds': ?mediaIds,
      'attributes': attributes,
      'listPrice': ?listPrice,
      'salePrice': ?salePrice,
      'quantityOnHand': ?quantityOnHand,
      'reorderLevel': ?reorderLevel,
      'weightGram': ?weightGram,
      'isActive': ?isActive,
    };
    final response = await _apiClient.put('/api/v1/admin/products/$productId/variants/$variantId', body);
    return ProductVariantSummary.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteVariant(String productId, String variantId) async {
    await _apiClient.delete('/api/v1/admin/products/$productId/variants/$variantId');
  }
}
