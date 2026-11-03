class PosCartItem {
  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final String sku;
  final String? variantCode;
  final String? thumbnailUrl;
  final double unitPrice;
  int quantity;
  final int stockAvailable;
  List<String> serialNumbers;

  PosCartItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.sku,
    this.variantCode,
    this.thumbnailUrl,
    required this.unitPrice,
    required this.quantity,
    required this.stockAvailable,
    List<String>? serialNumbers,
  }) : serialNumbers = serialNumbers ?? [];

  double get lineTotal => unitPrice * quantity;
}
