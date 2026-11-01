import 'package:flutter/foundation.dart';
import 'package:joppe_core/joppe_core.dart' as core;
import '../models/cart_item.dart';
import '../models/product.dart';
import 'app_api_client.dart';
import 'auth_service.dart';

/// Dịch vụ quản lý giỏ hàng Joppe E-Commerce (Singleton ChangeNotifier)
/// Sử dụng trực tiếp joppe_core.CartService để đồng bộ hai chiều với API backend (/api/v1/cart)
class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  CartService._internal() {
    _initAuthSync();
  }

  core.ApiClient get apiClient => AppApiClient.instance;
  core.CartService get _coreCart => core.CartService(apiClient);

  final List<CartItem> _items = [];

  void _initAuthSync() {
    AuthService().addListener(() {
      if (AuthService().isAuthenticated) {
        if (_items.isNotEmpty) {
          _mergeGuestCartToServer();
        } else {
          syncWithServer();
        }
      }
    });
  }

  void _mergeGuestCartToServer() async {
    if (!AuthService().isAuthenticated) return;
    try {
      final payload = _items
          .map((it) => {
                'variantId': it.variantId ?? it.product.variantId ?? it.product.id,
                'quantity': it.quantity,
              })
          .toList();
      await _coreCart.mergeCart(payload);
      await syncWithServer();
    } catch (_) {}
  }

  List<CartItem> get items => List.unmodifiable(_items);
  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  String get formattedSubtotal => Product.formatVnd(subtotal);

  void addItem(Product product, {int quantity = 1}) {
    if (quantity <= 0) return;

    final targetVariantId = product.variantId ?? product.id;
    final existingIndex = _items.indexWhere((item) =>
        item.product.id == product.id ||
        (item.variantId != null && (item.variantId == targetVariantId || item.variantId == product.id)) ||
        (item.product.variantId != null && item.product.variantId == targetVariantId));

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity, variantId: targetVariantId));
    }
    notifyListeners();

    if (AuthService().isAuthenticated) {
      _syncAddItem(targetVariantId, product.id, quantity);
    }
  }

  void _syncAddItem(String variantId, String productId, int quantity) async {
    try {
      final res = await _coreCart.addItem(variantId: variantId, quantity: quantity);
      for (final raw in res.items) {
        if (raw.variantId == variantId || raw.productId == productId) {
          final idx = _items.indexWhere((it) =>
              it.product.id == productId ||
              it.variantId == variantId ||
              it.product.variantId == variantId);
          if (idx >= 0) {
            _items[idx] = _items[idx].copyWith(cartItemId: raw.id, variantId: variantId);
            notifyListeners();
          }
          break;
        }
      }
    } catch (_) {}
  }

  void addMultipleProducts(List<Product> products) {
    for (final product in products) {
      final targetVariantId = product.variantId ?? product.id;
      final existingIndex = _items.indexWhere((item) =>
          item.product.id == product.id ||
          (item.variantId != null && (item.variantId == targetVariantId || item.variantId == product.id)) ||
          (item.product.variantId != null && item.product.variantId == targetVariantId));

      if (existingIndex >= 0) {
        _items[existingIndex].quantity += 1;
      } else {
        _items.add(CartItem(product: product, quantity: 1, variantId: targetVariantId));
      }
      if (AuthService().isAuthenticated) {
        _coreCart.addItem(variantId: targetVariantId, quantity: 1).catchError((_) => core.CartResponseModel.empty());
      }
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final existingIndex = _items.indexWhere((item) =>
        item.product.id == productId ||
        item.cartItemId == productId ||
        item.variantId == productId);

    if (existingIndex >= 0) {
      final item = _items[existingIndex];
      final targetId = item.cartItemId ?? item.variantId ?? productId;

      if (newQuantity <= 0) {
        _items.removeAt(existingIndex);
        if (AuthService().isAuthenticated) {
          _coreCart.removeItem(targetId).catchError((_) => core.CartResponseModel.empty());
        }
      } else {
        _items[existingIndex].quantity = newQuantity;
        if (AuthService().isAuthenticated) {
          _coreCart.updateQuantity(cartItemId: targetId, quantity: newQuantity).catchError((_) => core.CartResponseModel.empty());
        }
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    final existingIndex = _items.indexWhere((item) =>
        item.product.id == productId ||
        item.cartItemId == productId ||
        item.variantId == productId);

    if (existingIndex >= 0) {
      final item = _items[existingIndex];
      final targetId = item.cartItemId ?? item.variantId ?? productId;
      _items.removeAt(existingIndex);
      notifyListeners();
      if (AuthService().isAuthenticated) {
        _coreCart.removeItem(targetId).catchError((_) => core.CartResponseModel.empty());
      }
    }
  }

  void clearCart() {
    if (_items.isNotEmpty) {
      _items.clear();
      notifyListeners();
      if (AuthService().isAuthenticated) {
        _coreCart.clearCart().catchError((_) => core.CartResponseModel.empty());
      }
    }
  }

  Future<void> syncWithServer() async {
    if (!AuthService().isAuthenticated) return;
    try {
      final res = await _coreCart.getCart();
      if (res.items.isNotEmpty) {
        final serverItems = <CartItem>[];
        for (final item in res.items) {
          final prod = Product(
            id: item.variantId.isNotEmpty ? item.variantId : item.productId,
            variantId: item.variantId,
            name: item.variantName.isNotEmpty && item.variantName != 'Default'
                ? '${item.productName} (${item.variantName})'
                : item.productName,
            description: 'Linh kiện công nghệ chính hãng',
            price: item.unitPrice,
            originalPrice: item.listPrice,
            imageUrl: item.thumbnailUrl != null
                ? AppApiClient.instance.resolveMediaUrl(item.thumbnailUrl)
                : '',
            category: 'Linh kiện PC',
            brand: 'JOPPE',
            inStock: item.stockAvailable > 0,
          );

          serverItems.add(CartItem(
            product: prod,
            quantity: item.quantity,
            cartItemId: item.id,
            variantId: item.variantId,
          ));
        }
        _items.clear();
        _items.addAll(serverItems);
        notifyListeners();
      } else if (_items.isNotEmpty) {
        _mergeGuestCartToServer();
      }
    } catch (_) {}
  }

  @visibleForTesting
  void reset() {
    _items.clear();
  }
}
