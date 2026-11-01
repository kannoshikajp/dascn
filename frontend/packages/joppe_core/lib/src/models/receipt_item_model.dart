class ReceiptItemModel {
  final String id;
  final String variantId;
  final String productName;
  final String variantName;
  final String sku;
  final String? thumbnailUrl;
  final int quantity;
  final double importPrice;
  final double subtotal;

  const ReceiptItemModel({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.variantName,
    required this.sku,
    this.thumbnailUrl,
    required this.quantity,
    required this.importPrice,
    required this.subtotal,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptItemModel(
      id: json['id'] as String,
      variantId: json['variantId'] as String,
      productName: json['productName'] as String? ?? '',
      variantName: json['variantName'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      importPrice: (json['importPrice'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'variantId': variantId,
        'productName': productName,
        'variantName': variantName,
        'sku': sku,
        'thumbnailUrl': thumbnailUrl,
        'quantity': quantity,
        'importPrice': importPrice,
        'subtotal': subtotal,
      };
}
