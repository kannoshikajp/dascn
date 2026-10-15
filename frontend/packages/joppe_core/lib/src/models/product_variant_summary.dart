class ProductVariantSummary {
  final String id;
  final String sku;
  final String variantName;
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
    required this.variantName,
    this.listPrice = 0.0,
    this.salePrice = 0.0,
    this.quantityOnHand = 0,
    this.quantityReserved = 0,
    this.availableQuantity = 0,
    this.weightGram = 0.0,
    this.isActive = true,
  });

  factory ProductVariantSummary.fromJson(Map<String, dynamic> json) {
    return ProductVariantSummary(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      variantName: json['variantName'] as String? ?? '',
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
        'variantName': variantName,
        'listPrice': listPrice,
        'salePrice': salePrice,
        'quantityOnHand': quantityOnHand,
        'quantityReserved': quantityReserved,
        'availableQuantity': availableQuantity,
        'weightGram': weightGram,
        'isActive': isActive,
      };
}
