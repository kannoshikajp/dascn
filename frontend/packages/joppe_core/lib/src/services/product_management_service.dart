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

  Future<ProductItem> getProduct(String id) async {
    final response = await _apiClient.get('/api/v1/admin/products/$id');
    return ProductItem.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductItem> createProduct({
    required String productName,
    String? slug,
    int? brandId,
    List<int>? categoryIds,
    int? primaryCategoryId,
    String? shortDescription,
    String? description,
    String? specifications,
    int? warrantyMonths,
    String? thumbnailUrl,
    bool isActive = true,
    String? sku,
    double? listPrice,
    double? salePrice,
    int? stockQuantity,
  }) async {
    final body = {
      'productName': productName,
      if (slug != null && slug.isNotEmpty) 'slug': slug,
      'brandId': brandId,
      if (categoryIds != null) 'categoryIds': categoryIds,
      if (primaryCategoryId != null) 'primaryCategoryId': primaryCategoryId,
      'shortDescription': shortDescription,
      'description': description,
      'specifications': specifications,
      'warrantyMonths': warrantyMonths,
      'thumbnailUrl': thumbnailUrl,
      'isActive': isActive,
      if (sku != null && sku.isNotEmpty) 'sku': sku,
      if (listPrice != null) 'listPrice': listPrice,
      if (salePrice != null) 'salePrice': salePrice,
      if (stockQuantity != null) 'stockQuantity': stockQuantity,
    };

    final response = await _apiClient.post('/api/v1/admin/products', body);
    return ProductItem.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductItem> updateProduct({
    required String id,
    required String productName,
    String? slug,
    int? brandId,
    List<int>? categoryIds,
    int? primaryCategoryId,
    String? shortDescription,
    String? description,
    String? specifications,
    int? warrantyMonths,
    String? thumbnailUrl,
    bool? isActive,
  }) async {
    final body = {
      'productName': productName,
      if (slug != null && slug.isNotEmpty) 'slug': slug,
      'brandId': brandId,
      if (categoryIds != null) 'categoryIds': categoryIds,
      if (primaryCategoryId != null) 'primaryCategoryId': primaryCategoryId,
      'shortDescription': shortDescription,
      'description': description,
      'specifications': specifications,
      'warrantyMonths': warrantyMonths,
      'thumbnailUrl': thumbnailUrl,
      'isActive': isActive,
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
    required String variantName,
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
      'variantName': variantName,
      'attributes': attributes,
      if (listPrice != null) 'listPrice': listPrice,
      if (salePrice != null) 'salePrice': salePrice,
      if (quantityOnHand != null) 'quantityOnHand': quantityOnHand,
      if (reorderLevel != null) 'reorderLevel': reorderLevel,
      if (weightGram != null) 'weightGram': weightGram,
      'isActive': isActive,
    };
    final response = await _apiClient.post('/api/v1/admin/products/$productId/variants', body);
    return ProductVariantSummary.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductVariantSummary> updateVariant(
    String productId,
    String variantId, {
    required String sku,
    required String variantName,
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
      'variantName': variantName,
      'attributes': attributes,
      if (listPrice != null) 'listPrice': listPrice,
      if (salePrice != null) 'salePrice': salePrice,
      if (quantityOnHand != null) 'quantityOnHand': quantityOnHand,
      if (reorderLevel != null) 'reorderLevel': reorderLevel,
      if (weightGram != null) 'weightGram': weightGram,
      if (isActive != null) 'isActive': isActive,
    };
    final response = await _apiClient.put('/api/v1/admin/products/$productId/variants/$variantId', body);
    return ProductVariantSummary.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteVariant(String productId, String variantId) async {
    await _apiClient.delete('/api/v1/admin/products/$productId/variants/$variantId');
  }
}
