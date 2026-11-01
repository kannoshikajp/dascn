import 'product.dart';
import '../services/app_api_client.dart';

/// Model item trong giỏ hàng và danh sách sản phẩm thanh toán của Joppe E-Commerce
class CartItem {
  final Product product;
  int quantity;
  final DateTime addedAt;
  final String? cartItemId;
  final String? variantId;

  CartItem({
    required this.product,
    this.quantity = 1,
    DateTime? addedAt,
    this.cartItemId,
    this.variantId,
  }) : addedAt = addedAt ?? DateTime.now();

  /// Factory khởi tạo từ phản hồi CartResponse (/api/v1/cart) theo API_SCHEMA.md mục 10.1
  factory CartItem.fromApiJson(Map<String, dynamic> json) {
    final cartItemId = json['id']?.toString();
    final variantId = json['variantId']?.toString();
    final productId = json['productId']?.toString() ?? variantId ?? cartItemId ?? '';
    final productName = json['productName']?.toString() ?? 'Sản phẩm JOPPE';
    final variantName = json['variantName']?.toString();
    final fullName = (variantName != null && variantName.isNotEmpty && variantName != 'Default')
        ? '$productName ($variantName)'
        : productName;
    final unitPrice = (json['unitPrice'] as num?)?.toDouble() ?? 0.0;
    final listPrice = (json['listPrice'] as num?)?.toDouble();
    final qty = (json['quantity'] as num?)?.toInt() ?? 1;
    final rawThumb = json['thumbnailUrl']?.toString();
    final resolvedThumb = AppApiClient.instance.resolveMediaUrl(rawThumb);
    final stockAvailable = (json['stockAvailable'] as num?)?.toInt() ?? 10;

    final product = Product(
      id: variantId ?? productId,
      name: fullName,
      description: 'Linh kiện công nghệ chính hãng',
      price: unitPrice,
      originalPrice: listPrice,
      imageUrl: resolvedThumb,
      category: 'Linh kiện PC',
      brand: 'JOPPE',
      inStock: stockAvailable > 0,
    );

    return CartItem(
      product: product,
      quantity: qty,
      cartItemId: cartItemId,
      variantId: variantId,
    );
  }

  /// Tổng tiền của dòng sản phẩm này theo số lượng
  double get totalPrice => product.price * quantity;

  /// Tổng tiền hiển thị định dạng VND chuẩn (ví dụ: "28.580.000 ₫")
  String get formattedTotalPrice => Product.formatVnd(totalPrice);

  /// Tạo bản sao với các thuộc tính được cập nhật
  CartItem copyWith({
    Product? product,
    int? quantity,
    DateTime? addedAt,
    String? cartItemId,
    String? variantId,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      cartItemId: cartItemId ?? this.cartItemId,
      variantId: variantId ?? this.variantId,
    );
  }

  /// Chuyển đổi sang JSON Map
  Map<String, dynamic> toJson() {
    return {
      if (cartItemId != null) 'id': cartItemId,
      if (variantId != null) 'variantId': variantId,
      'productId': product.id,
      'productName': product.name,
      'productPrice': product.price,
      'imageUrl': product.imageUrl,
      'brand': product.brand,
      'category': product.category,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'CartItem(product: ${product.name}, qty: $quantity, total: $formattedTotalPrice)';
}
