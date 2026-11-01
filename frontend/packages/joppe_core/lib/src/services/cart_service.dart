import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/cart_response_model.dart';

class CartService {
  final ApiClient _client;

  CartService(this._client);

  Future<CartResponseModel> getCart() async {
    final response = await _client.get(ApiConstants.cart);
    return CartResponseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<CartResponseModel> addItem({
    required String variantId,
    required int quantity,
  }) async {
    final response = await _client.post(ApiConstants.cartItems, {
      'variantId': variantId,
      'quantity': quantity,
    });
    return CartResponseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<CartResponseModel> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final response = await _client.put('${ApiConstants.cartItems}/$cartItemId', {
      'quantity': quantity,
    });
    return CartResponseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<CartResponseModel> removeItem(String cartItemId) async {
    final response = await _client.delete('${ApiConstants.cartItems}/$cartItemId');
    return CartResponseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<CartResponseModel> clearCart() async {
    final response = await _client.delete(ApiConstants.cart);
    return CartResponseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<CartResponseModel> mergeCart(List<Map<String, dynamic>> items) async {
    final response = await _client.post(ApiConstants.cartMerge, {
      'items': items,
    });
    return CartResponseModel.fromJson(response as Map<String, dynamic>);
  }
}
