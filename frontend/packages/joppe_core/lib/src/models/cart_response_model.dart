import 'cart_item_model.dart';

class CartResponseModel {
  final List<CartItemModel> items;
  final int totalItems;
  final double subtotalAmount;

  const CartResponseModel({
    required this.items,
    required this.totalItems,
    required this.subtotalAmount,
  });

  factory CartResponseModel.empty() => const CartResponseModel(
        items: [],
        totalItems: 0,
        subtotalAmount: 0.0,
      );

  factory CartResponseModel.fromJson(Map<String, dynamic> json) {
    return CartResponseModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      subtotalAmount: (json['subtotalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'totalItems': totalItems,
        'subtotalAmount': subtotalAmount,
      };
}
