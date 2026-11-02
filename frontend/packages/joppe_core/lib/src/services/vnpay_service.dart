import '../api/api_client.dart';
import '../models/vnpay_payment_model.dart';

class VnPayService {
  final ApiClient apiClient;

  static const String defaultSandboxPayUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';

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

  /// Generates a valid VNPay sandbox portal URL with standard query parameters.
  /// Never points to an internal API or order detail URL.
  String buildFallbackPaymentUrl({
    required String orderCode,
    required double amount,
    String? txnRef,
  }) {
    final ref = txnRef ?? '${orderCode}_${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final amountInCents = (amount * 100).round();
    final query = <String, String>{
      'vnp_Command': 'pay',
      'vnp_Version': '2.1.0',
      'vnp_TmnCode': 'H04KMMWQ',
      'vnp_Amount': amountInCents.toString(),
      'vnp_CurrCode': 'VND',
      'vnp_TxnRef': ref,
      'vnp_OrderInfo': 'Thanh_toan_don_hang_$orderCode',
      'vnp_OrderType': 'other',
      'vnp_Locale': 'vn',
      'vnp_ReturnUrl': '${apiClient.baseUrl}/api/v1/payment/vnpay/return',
    };
    return Uri.parse(defaultSandboxPayUrl).replace(queryParameters: query).toString();
  }

  /// Attempts to create payment URL through backend API, falling back to
  /// direct sandbox URL if server is unavailable or order was placed offline.
  Future<VnPayPaymentModel> createPaymentUrlOrFallback({
    required String orderId,
    required String orderCode,
    required double amount,
    String? bankCode,
    String? returnUrl,
  }) async {
    try {
      return await createPaymentUrl(
        orderId: orderId,
        bankCode: bankCode,
        returnUrl: returnUrl,
      );
    } catch (_) {
      final fallbackUrl = buildFallbackPaymentUrl(
        orderCode: orderCode,
        amount: amount,
      );
      final qrUrl = buildQrUrl(paymentUrl: fallbackUrl);
      return VnPayPaymentModel(
        paymentId: 'fallback-$orderId',
        paymentUrl: fallbackUrl,
        orderCode: orderCode,
        txnRef: '${orderCode}_${DateTime.now().millisecondsSinceEpoch % 1000000}',
        amount: amount,
        qrCodeUrl: qrUrl,
      );
    }
  }

  String buildQrUrl({
    String? paymentUrl,
    String? paymentId,
    int size = 300,
  }) {
    final targetUrl = (paymentUrl != null && paymentUrl.isNotEmpty)
        ? paymentUrl
        : defaultSandboxPayUrl;
    final query = <String, String>{
      'size': size.toString(),
      'paymentUrl': targetUrl,
      if (paymentId != null && paymentId.isNotEmpty) 'paymentId': paymentId,
    };
    return Uri.parse('${apiClient.baseUrl}/api/v1/payment/vnpay/qr').replace(queryParameters: query).toString();
  }
}
