import 'product_category_summary.dart';
import 'product_variant_summary.dart';

class ProductItem {
  final String id;
  final String productName;
  final String sku;
  final String? parentSku;
  final String slug;
  final int? brandId;
  final String? brandName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ProductCategorySummary> categories;
  final List<ProductVariantSummary> variants;
  final double minPrice;
  final double maxPrice;
  final int totalStock;

  const ProductItem({
    required this.id,
    required this.productName,
    this.sku = '',
    this.parentSku,
    required this.slug,
    this.brandId,
    this.brandName,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.categories = const [],
    this.variants = const [],
    this.minPrice = 0.0,
    this.maxPrice = 0.0,
    this.totalStock = 0,
  });

  String? get versionCode => sku;

  /// Effective display price: prioritize minPrice if > 0, then maxPrice, then variant salePrice / listPrice
  double get effectivePrice {
    if (minPrice > 0) return minPrice;
    if (maxPrice > 0) return maxPrice;
    for (final v in variants) {
      if (v.salePrice > 0) return v.salePrice;
      if (v.listPrice > 0) return v.listPrice;
    }
    return 0.0;
  }

  /// Primary thumbnail resolved from default variant
  String? get thumbnailUrl {
    for (final v in variants) {
      if (v.thumbnailUrl != null && v.thumbnailUrl!.isNotEmpty) {
        return v.thumbnailUrl;
      }
    }
    return null;
  }

  /// Primary description resolved from default variant
  String? get description => variants.isNotEmpty ? variants.first.description : null;

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      sku: json['sku'] as String? ?? (json['versionCode'] as String? ?? ''),
      parentSku: json['parentSku'] as String?,
      slug: json['slug'] as String? ?? '',
      brandId: json['brandId'] as int?,
      brandName: json['brandName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((item) => ProductCategorySummary.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      variants: (json['variants'] as List<dynamic>?)
              ?.map((item) => ProductVariantSummary.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['maxPrice'] as num?)?.toDouble() ?? 0.0,
      totalStock: (json['totalStock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productName': productName,
        'sku': sku,
        'parentSku': parentSku,
        'slug': slug,
        'brandId': brandId,
        'brandName': brandName,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'variants': variants.map((v) => v.toJson()).toList(),
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'totalStock': totalStock,
      };
}
