import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../api/api_client.dart';
import '../models/vnpay_payment_model.dart';

class VnPayService {
  final ApiClient apiClient;

  static const String defaultSandboxPayUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String defaultSandboxTmnCode = 'H04KMMWQ';
  static const String defaultSandboxHashSecret = 'QSRCXQVXSJPTZJDSAPEKSGMMUEPBOGSA';

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

  /// Checks real-time payment status from backend for live polling
  Future<Map<String, dynamic>> checkPaymentStatus({
    String? orderCode,
    String? txnRef,
    String? orderId,
  }) async {
    final query = <String, String>{
      if (orderCode != null && orderCode.isNotEmpty) 'orderCode': orderCode,
      if (txnRef != null && txnRef.isNotEmpty) 'txnRef': txnRef,
      if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
    };
    final res = await apiClient.get('/api/v1/payment/vnpay/status', query);
    return Map<String, dynamic>.from(res as Map);
  }

  /// Generates a fully signed VNPay portal URL compliant with VNPay v2.1.0 specifications.
  /// Includes vnp_CreateDate, vnp_IpAddr, sorted query parameters, and HMAC-SHA512 checksum.
  String buildFallbackPaymentUrl({
    required String orderCode,
    required double amount,
    String? txnRef,
    String? bankCode,
    String tmnCode = defaultSandboxTmnCode,
    String hashSecret = defaultSandboxHashSecret,
    String? ipAddr,
  }) {
    final ref = txnRef ?? '${orderCode}_${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final amountInCents = (amount * 100).round();
    final createDate = _formatVnPayDate(DateTime.now());
    final cleanOrderCode = orderCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    final params = <String, String>{
      'vnp_Version': '2.1.0',
      'vnp_Command': 'pay',
      'vnp_TmnCode': tmnCode,
      'vnp_Amount': amountInCents.toString(),
      'vnp_CurrCode': 'VND',
      'vnp_TxnRef': ref,
      'vnp_OrderInfo': 'Thanh_toan_don_hang_$cleanOrderCode',
      'vnp_OrderType': 'other',
      'vnp_Locale': 'vn',
      'vnp_ReturnUrl': '${apiClient.baseUrl}/api/v1/payment/vnpay/return',
      'vnp_IpAddr': ipAddr ?? '127.0.0.1',
      'vnp_CreateDate': createDate,
      if (bankCode != null && bankCode.trim().isNotEmpty) 'vnp_BankCode': bankCode.trim(),
    };

    // Sort parameters alphabetically by key as required by VNPay gateway
    final sortedKeys = params.keys.toList()..sort();

    final hashData = sortedKeys
        .map((k) => '$k=${Uri.encodeQueryComponent(params[k]!)}')
        .join('&');

    final query = sortedKeys
        .map((k) => '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(params[k]!)}')
        .join('&');

    final hmac = Hmac(sha512, utf8.encode(hashSecret));
    final secureHash = hmac.convert(utf8.encode(hashData)).toString();

    return '$defaultSandboxPayUrl?$query&vnp_SecureHash=$secureHash';
  }

  static String _formatVnPayDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y$m$d$h$min$s';
  }

  /// Attempts to create payment URL through backend API, falling back to
  /// a fully signed sandbox URL if server is unavailable or order was placed offline.
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
        bankCode: bankCode,
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
