class InventoryStockItem {
  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final String sku;
  final String? variantCode;
  final String? thumbnailUrl;
  final double salePrice;
  final double listPrice;
  final int quantityOnHand;
  final int quantityReserved;
  final int stockAvailable;
  final int reorderLevel;
  final bool isLowStock;
  final bool isOutOfStock;

  const InventoryStockItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.sku,
    this.variantCode,
    this.thumbnailUrl,
    required this.salePrice,
    required this.listPrice,
    required this.quantityOnHand,
    required this.quantityReserved,
    required this.stockAvailable,
    required this.reorderLevel,
    required this.isLowStock,
    required this.isOutOfStock,
  });

  factory InventoryStockItem.fromJson(Map<String, dynamic> json) {
    return InventoryStockItem(
      variantId: json['variantId'] as String,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      variantName: json['variantName'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      variantCode: json['variantCode'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      listPrice: (json['listPrice'] as num?)?.toDouble() ?? 0.0,
      quantityOnHand: (json['quantityOnHand'] as num?)?.toInt() ?? 0,
      quantityReserved: (json['quantityReserved'] as num?)?.toInt() ?? 0,
      stockAvailable: (json['stockAvailable'] as num?)?.toInt() ?? 0,
      reorderLevel: (json['reorderLevel'] as num?)?.toInt() ?? 10,
      isLowStock: json['isLowStock'] as bool? ?? false,
      isOutOfStock: json['isOutOfStock'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'productId': productId,
        'productName': productName,
        'variantName': variantName,
        'sku': sku,
        'variantCode': variantCode,
        'thumbnailUrl': thumbnailUrl,
        'salePrice': salePrice,
        'listPrice': listPrice,
        'quantityOnHand': quantityOnHand,
        'quantityReserved': quantityReserved,
        'stockAvailable': stockAvailable,
        'reorderLevel': reorderLevel,
        'isLowStock': isLowStock,
        'isOutOfStock': isOutOfStock,
      };
}
