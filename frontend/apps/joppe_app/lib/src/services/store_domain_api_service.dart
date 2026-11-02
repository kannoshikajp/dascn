import 'package:joppe_core/joppe_core.dart' as core;
import 'app_api_client.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;
  final String? errorMessage;

  const ApiResponse({
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  factory ApiResponse.success(int statusCode, dynamic data) {
    return ApiResponse(statusCode: statusCode, data: data);
  }

  factory ApiResponse.failure(int statusCode, String errorMessage, [dynamic data]) {
    return ApiResponse(
      statusCode: statusCode,
      errorMessage: errorMessage,
      data: data,
    );
  }
}

/// Dịch vụ kết nối API cho toàn bộ các nghiệp vụ lõi của sàn Joppe
/// Kết nối và ủy thác thông qua gói trung tâm joppe_core
class StoreDomainApiService {
  static final StoreDomainApiService _instance = StoreDomainApiService._internal();
  factory StoreDomainApiService() => _instance;
  StoreDomainApiService._internal();

  core.ApiClient get _client => AppApiClient.instance;
  core.AddressService get _addressService => core.AddressService(_client);
  core.OrderService get _orderService => core.OrderService(_client);
  core.PcBuilderService get _pcBuilderService => core.PcBuilderService(_client);

  Future<ApiResponse> _wrap(Future<dynamic> Function() action) async {
    try {
      final res = await action();
      return ApiResponse.success(200, res);
    } on core.ApiException catch (e) {
      return ApiResponse.failure(e.statusCode, e.message, e.data);
    } catch (e) {
      return ApiResponse.failure(500, 'Lỗi kết nối máy chủ: $e');
    }
  }

  // ==========================================
  // CUSTOMER ADDRESS BOOK (/api/v1/addresses)
  // ==========================================

  Future<ApiResponse> listAddresses() async {
    return _wrap(() async {
      final res = await _client.get(core.ApiConstants.addresses);
      return res;
    });
  }

  Future<ApiResponse> getAddress(String id) async {
    return _wrap(() async {
      final res = await _client.get('${core.ApiConstants.addresses}/$id');
      return res;
    });
  }

  Future<ApiResponse> addAddress({
    required String recipientName,
    required String recipientPhone,
    required String streetAddress,
    String? ward,
    String? district,
    required String province,
    bool isDefault = false,
  }) async {
    return _wrap(() async {
      final res = await _addressService.createAddress(
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        streetAddress: streetAddress,
        ward: ward,
        district: district,
        province: province,
        isDefault: isDefault,
      );
      return res.toJson();
    });
  }

  Future<ApiResponse> updateAddress(String id, Map<String, dynamic> addressData) async {
    return _wrap(() async {
      final res = await _client.put('${core.ApiConstants.addresses}/$id', addressData);
      return res;
    });
  }

  Future<ApiResponse> setDefaultAddress(String id) async {
    return _wrap(() async {
      await _addressService.setDefaultAddress(id);
      return {'success': true};
    });
  }

  Future<ApiResponse> deleteAddress(String id) async {
    return _wrap(() async {
      await _addressService.deleteAddress(id);
      return {'success': true};
    });
  }

  // ==========================================
  // CUSTOMER ORDERS & CHECKOUT (/api/v1/orders)
  // ==========================================

  Future<ApiResponse> checkoutOrder({
    required String recipientName,
    required String recipientPhone,
    required String shippingAddress,
    String? customerNote,
    double shippingFee = 0.0,
    List<Map<String, dynamic>>? items,
    String? paymentMethod,
    String? paymentStatus,
  }) async {
    return _wrap(() async {
      final res = await _orderService.checkout(
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        shippingAddress: shippingAddress,
        customerNote: customerNote,
        shippingFee: shippingFee,
        items: items,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
      );
      return res.toJson();
    });
  }

  Future<ApiResponse> getMyOrders() async {
    return _wrap(() async {
      final res = await _client.get(core.ApiConstants.ordersMy);
      return res;
    });
  }

  Future<ApiResponse> getOrderDetails(String orderId) async {
    return _wrap(() async {
      final res = await _client.get('${core.ApiConstants.orders}/$orderId');
      return res;
    });
  }

  Future<ApiResponse> cancelOrder(String orderId) async {
    return _wrap(() async {
      final res = await _orderService.cancelOrder(orderId);
      return res.toJson();
    });
  }

  // ==========================================
  // VNPAY GATEWAY & QR PAYMENT (/api/v1/payment/vnpay)
  // ==========================================

  Future<ApiResponse> createVnPayPayment({
    required String orderId,
    String? bankCode,
    String? returnUrl,
    String? orderCode,
    double? amount,
  }) async {
    return _wrap(() async {
      final res = await core.VnPayService(_client).createPaymentUrlOrFallback(
        orderId: orderId,
        orderCode: orderCode ?? orderId,
        amount: amount ?? 0.0,
        bankCode: bankCode,
        returnUrl: returnUrl,
      );
      return res.toJson();
    });
  }

  String buildVnPayQrUrl({
    String? paymentUrl,
    String? paymentId,
    int size = 300,
  }) {
    return core.VnPayService(_client).buildQrUrl(
      paymentUrl: paymentUrl,
      paymentId: paymentId,
      size: size,
    );
  }

  // ==========================================
  // PC BUILDER & COMPATIBILITY (/api/v1/pc-builder)
  // ==========================================

  Future<ApiResponse> simulateBuild(Map<String, dynamic> components) async {
    return _wrap(() => _pcBuilderService.simulateBuild(components));
  }

  Future<ApiResponse> saveBuild(Map<String, dynamic> buildData) async {
    return _wrap(() => _pcBuilderService.saveBuild(buildData));
  }

  Future<ApiResponse> getMyBuilds() async {
    return _wrap(() => _pcBuilderService.getMyBuilds());
  }

  Future<ApiResponse> addBuildToCart(String buildId) async {
    return _wrap(() => _pcBuilderService.addBuildToCart(buildId));
  }

  // ==========================================
  // CUSTOMER REVIEWS & RATINGS (/api/v1/reviews)
  // ==========================================

  Future<ApiResponse> getProductReviews(String productId) async {
    return _wrap(() => _client.get('${core.ApiConstants.products}/$productId/reviews'));
  }

  Future<ApiResponse> submitProductReview(String productId, Map<String, dynamic> reviewData) async {
    return _wrap(() => _client.post('${core.ApiConstants.products}/$productId/reviews', reviewData));
  }
}
