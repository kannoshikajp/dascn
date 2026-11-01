import '../api/api_client.dart';
import '../models/vnpay_payment_model.dart';

class VnPayService {
  final ApiClient apiClient;

  const VnPayService(this.apiClient);

  Future<VnPayPaymentModel> createPaymentUrl({
    required String orderId,
    String? bankCode,
    String? returnUrl,
  }) async {
    final payload = <String, dynamic>{
      'orderId': orderId,
      if (bankCode != null && bankCode.isNotEmpty) 'bankCode': bankCode,
      if (returnUrl != null && returnUrl.isNotEmpty) 'returnUrl': returnUrl,
    };

    final res = await apiClient.post('/api/v1/payment/vnpay/create', payload);
    return VnPayPaymentModel.fromJson(res as Map<String, dynamic>);
  }

  String buildQrUrl({
    String? paymentUrl,
    String? paymentId,
    int size = 300,
  }) {
    final query = <String, String>{
      'size': size.toString(),
      if (paymentUrl != null && paymentUrl.isNotEmpty) 'paymentUrl': paymentUrl,
      if (paymentId != null && paymentId.isNotEmpty) 'paymentId': paymentId,
    };
    return Uri.parse('${apiClient.baseUrl}/api/v1/payment/vnpay/qr').replace(queryParameters: query).toString();
  }
}
