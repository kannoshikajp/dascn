import '../api/api_client.dart';
import '../api/api_constants.dart';
import '../models/order_detail_model.dart';
import '../models/order_summary_model.dart';

class OrderService {
  final ApiClient _client;

  OrderService(this._client);

  // Customer Operations
  Future<OrderDetailModel> checkout({
    required String recipientName,
    required String recipientPhone,
    required String shippingAddress,
    String? customerNote,
    double? shippingFee,
    List<Map<String, dynamic>>? items,
    String? paymentMethod,
    String? paymentStatus,
  }) async {
    final response = await _client.post(ApiConstants.ordersCheckout, {
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'shippingAddress': shippingAddress,
      if (customerNote != null) 'customerNote': customerNote,
      if (shippingFee != null) 'shippingFee': shippingFee,
      if (items != null) 'items': items,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
    });
    return OrderDetailModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<OrderSummaryModel>> getMyOrders() async {
    final response = await _client.get(ApiConstants.ordersMy);
    if (response is List) {
      return response
          .map((e) => OrderSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<OrderDetailModel> getCustomerOrder(String id) async {
    final response = await _client.get('${ApiConstants.orders}/$id');
    return OrderDetailModel.fromJson(response as Map<String, dynamic>);
  }

  Future<OrderDetailModel> cancelOrder(String id) async {
    final response = await _client.post('${ApiConstants.orders}/$id/cancel');
    return OrderDetailModel.fromJson(response as Map<String, dynamic>);
  }

  // Administrative Operations
  Future<OrderDetailModel> createAdminOrder({
    String? userId,
    String? customerEmail,
    required String recipientName,
    required String recipientPhone,
    required String shippingAddress,
    String? customerNote,
    double? shippingFee,
    String? orderStatus,
    String? paymentStatus,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.post(ApiConstants.adminOrders, {
      if (userId != null) 'userId': userId,
      if (customerEmail != null) 'customerEmail': customerEmail,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'shippingAddress': shippingAddress,
      if (customerNote != null) 'customerNote': customerNote,
      if (shippingFee != null) 'shippingFee': shippingFee,
      if (orderStatus != null) 'orderStatus': orderStatus,
      if (paymentStatus != null) 'paymentStatus': paymentStatus,
      'items': items,
    });
    return OrderDetailModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<OrderSummaryModel>> listAdminOrders({
    String? status,
    String? paymentStatus,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      queryParams['paymentStatus'] = paymentStatus;
    }
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _client.get(ApiConstants.adminOrders, queryParams);
    if (response is List) {
      return response
          .map((e) => OrderSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<OrderDetailModel> getAdminOrderDetail(String id) async {
    final response = await _client.get('${ApiConstants.adminOrders}/$id');
    return OrderDetailModel.fromJson(response as Map<String, dynamic>);
  }

  Future<OrderDetailModel> updateOrderStatus(String id, String status) async {
    final response = await _client.patch('${ApiConstants.adminOrders}/$id/status', {
      'status': status,
    });
    return OrderDetailModel.fromJson(response as Map<String, dynamic>);
  }

  Future<OrderDetailModel> updatePaymentStatus(String id, String paymentStatus) async {
    final response = await _client.patch('${ApiConstants.adminOrders}/$id/payment-status', {
      'paymentStatus': paymentStatus,
    });
    return OrderDetailModel.fromJson(response as Map<String, dynamic>);
  }

  Future<OrderDetailModel> manualPaymentConfirm(
    String id, {
    required String referenceCode,
    String? note,
    String? managerPin,
  }) async {
    final response = await _client.post('${ApiConstants.adminOrders}/$id/manual-payment-confirm', {
      'referenceCode': referenceCode,
      if (note != null && note.isNotEmpty) 'note': note,
      if (managerPin != null && managerPin.isNotEmpty) 'managerPin': managerPin,
    });
    return OrderDetailModel.fromJson(response as Map<String, dynamic>);
  }
}
