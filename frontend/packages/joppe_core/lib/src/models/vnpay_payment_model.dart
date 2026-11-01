class VnPayPaymentModel {
  final String paymentId;
  final String paymentUrl;
  final String orderCode;
  final String txnRef;
  final double amount;
  final String? qrCodeUrl;
  final String? qrCodeBase64;

  const VnPayPaymentModel({
    required this.paymentId,
    required this.paymentUrl,
    required this.orderCode,
    required this.txnRef,
    required this.amount,
    this.qrCodeUrl,
    this.qrCodeBase64,
  });

  factory VnPayPaymentModel.fromJson(Map<String, dynamic> json) {
    return VnPayPaymentModel(
      paymentId: json['paymentId'] as String? ?? '',
      paymentUrl: json['paymentUrl'] as String? ?? '',
      orderCode: json['orderCode'] as String? ?? '',
      txnRef: json['txnRef'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      qrCodeUrl: json['qrCodeUrl'] as String?,
      qrCodeBase64: json['qrCodeBase64'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentId': paymentId,
      'paymentUrl': paymentUrl,
      'orderCode': orderCode,
      'txnRef': txnRef,
      'amount': amount,
      'qrCodeUrl': qrCodeUrl,
      'qrCodeBase64': qrCodeBase64,
    };
  }

  String? getFullQrUrl(String baseUrl) {
    if (qrCodeUrl == null || qrCodeUrl!.isEmpty) return null;
    if (qrCodeUrl!.startsWith('http://') || qrCodeUrl!.startsWith('https://')) {
      return qrCodeUrl;
    }
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = qrCodeUrl!.startsWith('/') ? qrCodeUrl! : '/$qrCodeUrl';
    return '$cleanBase$cleanPath';
  }
}
