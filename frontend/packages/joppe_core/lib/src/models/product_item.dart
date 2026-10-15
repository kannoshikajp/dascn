import 'product_category_summary.dart';
import 'product_variant_summary.dart';

class ProductItem {
  final String id;
  final String productName;
  final String slug;
  final int? brandId;
  final String? brandName;
  final String? shortDescription;
  final String? description;
  final String? specifications;
  final int warrantyMonths;
  final String? thumbnailUrl;
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
    required this.slug,
    this.brandId,
    this.brandName,
    this.shortDescription,
    this.description,
    this.specifications,
    this.warrantyMonths = 0,
    this.thumbnailUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.categories = const [],
    this.variants = const [],
    this.minPrice = 0.0,
    this.maxPrice = 0.0,
    this.totalStock = 0,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      brandId: json['brandId'] as int?,
      brandName: json['brandName'] as String?,
      shortDescription: json['shortDescription'] as String?,
      description: json['description'] as String?,
      specifications: json['specifications'] as String?,
      warrantyMonths: (json['warrantyMonths'] as num?)?.toInt() ?? 0,
      thumbnailUrl: json['thumbnailUrl'] as String?,
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
        'slug': slug,
        'brandId': brandId,
        'brandName': brandName,
        'shortDescription': shortDescription,
        'description': description,
        'specifications': specifications,
        'warrantyMonths': warrantyMonths,
        'thumbnailUrl': thumbnailUrl,
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
