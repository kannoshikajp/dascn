class OrderSummaryModel {
  final String id;
  final String orderCode;
  final String userId;
  final String orderStatus;
  final String paymentStatus;
  final String recipientName;
  final String recipientPhone;
  final double finalAmount;
  final int totalItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String orderChannel;
  final DateTime? paidAt;
  final DateTime? deliveredAt;

  const OrderSummaryModel({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.orderStatus,
    required this.paymentStatus,
    required this.recipientName,
    required this.recipientPhone,
    required this.finalAmount,
    required this.totalItems,
    this.createdAt,
    this.updatedAt,
    this.orderChannel = 'ONLINE',
    this.paidAt,
    this.deliveredAt,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) {
    return OrderSummaryModel(
      id: json['id'] as String,
      orderCode: json['orderCode'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      orderStatus: json['orderStatus'] as String? ?? 'ACCEPTED',
      paymentStatus: json['paymentStatus'] as String? ?? 'PAID',
      recipientName: json['recipientName'] as String? ?? '',
      recipientPhone: json['recipientPhone'] as String? ?? '',
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      orderChannel: json['orderChannel'] as String? ?? 'ONLINE',
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderCode': orderCode,
        'userId': userId,
        'orderStatus': orderStatus,
        'paymentStatus': paymentStatus,
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'finalAmount': finalAmount,
        'totalItems': totalItems,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'orderChannel': orderChannel,
        'paidAt': paidAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
      };
}
