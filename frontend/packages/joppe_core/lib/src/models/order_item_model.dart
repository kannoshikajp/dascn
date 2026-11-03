class OrderItemModel {
  final String id;
  final String? variantId;
  final String skuSnapshot;
  final String productNameSnapshot;
  final String variantNameSnapshot;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final int warrantyMonthsSnapshot;
  final String? thumbnailUrl;
  final List<String> serialNumbers;

  const OrderItemModel({
    required this.id,
    this.variantId,
    required this.skuSnapshot,
    required this.productNameSnapshot,
    required this.variantNameSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.warrantyMonthsSnapshot = 12,
    this.thumbnailUrl,
    this.serialNumbers = const [],
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      variantId: json['variantId'] as String?,
      skuSnapshot: json['skuSnapshot'] as String? ?? '',
      productNameSnapshot: json['productNameSnapshot'] as String? ?? '',
      variantNameSnapshot: json['variantNameSnapshot'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      warrantyMonthsSnapshot: (json['warrantyMonthsSnapshot'] as num?)?.toInt() ?? 12,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      serialNumbers: (json['serialNumbers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'variantId': variantId,
        'skuSnapshot': skuSnapshot,
        'productNameSnapshot': productNameSnapshot,
        'variantNameSnapshot': variantNameSnapshot,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'subtotal': subtotal,
        'warrantyMonthsSnapshot': warrantyMonthsSnapshot,
        'thumbnailUrl': thumbnailUrl,
        'serialNumbers': serialNumbers,
      };
}
