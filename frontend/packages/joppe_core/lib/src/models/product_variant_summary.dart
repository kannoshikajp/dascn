import 'dart:convert';

class ProductVariantSummary {
  final String id;
  final String sku;
  final String? parentSku;
  final String versionCode;
  final String variantCode;
  final String variantName;
  final String? compositeSlug;
  final String? thumbnailUrl;
  final String? description;
  final List<String> albumUrls;
  final List<String> albumMediaIds;
  final String? attributes;
  final double listPrice;
  final double salePrice;
  final int quantityOnHand;
  final int quantityReserved;
  final int availableQuantity;
  final double weightGram;
  final bool isActive;

  const ProductVariantSummary({
    required this.id,
    required this.sku,
    this.parentSku,
    this.versionCode = 'V1',
    this.variantCode = '',
    required this.variantName,
    this.compositeSlug,
    this.thumbnailUrl,
    this.description,
    this.albumUrls = const [],
    this.albumMediaIds = const [],
    this.attributes,
    this.listPrice = 0.0,
    this.salePrice = 0.0,
    this.quantityOnHand = 0,
    this.quantityReserved = 0,
    this.availableQuantity = 0,
    this.weightGram = 0.0,
    this.isActive = true,
  });

  Map<String, dynamic> get parsedAttributes {
    if (attributes == null || attributes!.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(attributes!);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  factory ProductVariantSummary.fromJson(Map<String, dynamic> json) {
    return ProductVariantSummary(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      parentSku: json['parentSku'] as String?,
      versionCode: json['versionCode'] as String? ?? 'V1',
      variantCode: json['variantCode'] as String? ?? (json['sku'] as String? ?? ''),
      variantName: json['variantName'] as String? ?? '',
      compositeSlug: json['compositeSlug'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      description: json['description'] as String?,
      albumUrls: (json['albumUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      albumMediaIds: (json['albumMediaIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      attributes: json['attributes'] as String?,
      listPrice: (json['listPrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      quantityOnHand: (json['quantityOnHand'] as num?)?.toInt() ?? 0,
      quantityReserved: (json['quantityReserved'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      weightGram: (json['weightGram'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'versionCode': versionCode,
        'variantCode': variantCode,
        'variantName': variantName,
        'compositeSlug': compositeSlug,
        'thumbnailUrl': thumbnailUrl,
        'description': description,
        'albumUrls': albumUrls,
        'albumMediaIds': albumMediaIds,
        'attributes': attributes,
        'listPrice': listPrice,
        'salePrice': salePrice,
        'quantityOnHand': quantityOnHand,
        'quantityReserved': quantityReserved,
        'availableQuantity': availableQuantity,
        'weightGram': weightGram,
        'isActive': isActive,
      };
}
