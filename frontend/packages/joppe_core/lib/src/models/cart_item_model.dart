class CartItemModel {
  final String id;
  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final String sku;
  final String? variantCode;
  final String compositeSlug;
  final String? thumbnailUrl;
  final double unitPrice;
  final double listPrice;
  final int quantity;
  final int stockAvailable;
  final double itemTotal;

  const CartItemModel({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.sku,
    this.variantCode,
    required this.compositeSlug,
    this.thumbnailUrl,
    required this.unitPrice,
    required this.listPrice,
    required this.quantity,
    required this.stockAvailable,
    required this.itemTotal,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      variantId: json['variantId'] as String,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      variantName: json['variantName'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      variantCode: json['variantCode'] as String?,
      compositeSlug: json['compositeSlug'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      listPrice: (json['listPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      stockAvailable: (json['stockAvailable'] as num?)?.toInt() ?? 0,
      itemTotal: (json['itemTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'variantId': variantId,
        'productId': productId,
        'productName': productName,
        'variantName': variantName,
        'sku': sku,
        'variantCode': variantCode,
        'compositeSlug': compositeSlug,
        'thumbnailUrl': thumbnailUrl,
        'unitPrice': unitPrice,
        'listPrice': listPrice,
        'quantity': quantity,
        'stockAvailable': stockAvailable,
        'itemTotal': itemTotal,
      };
}
