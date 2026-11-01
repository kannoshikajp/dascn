import 'order_item_model.dart';

class OrderDetailModel {
  final String id;
  final String orderCode;
  final String userId;
  final String orderStatus;
  final String paymentStatus;
  final String recipientName;
  final String recipientPhone;
  final String shippingAddress;
  final double subtotalAmount;
  final double discountAmount;
  final double shippingFee;
  final double finalAmount;
  final String? customerNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OrderItemModel> items;
  final String orderChannel;
  final DateTime? paidAt;
  final DateTime? deliveredAt;

  const OrderDetailModel({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.orderStatus,
    required this.paymentStatus,
    required this.recipientName,
    required this.recipientPhone,
    required this.shippingAddress,
    required this.subtotalAmount,
    required this.discountAmount,
    required this.shippingFee,
    required this.finalAmount,
    this.customerNote,
    this.createdAt,
    this.updatedAt,
    required this.items,
    this.orderChannel = 'ONLINE',
    this.paidAt,
    this.deliveredAt,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'] as String,
      orderCode: json['orderCode'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      orderStatus: json['orderStatus'] as String? ?? 'ACCEPTED',
      paymentStatus: json['paymentStatus'] as String? ?? 'PAID',
      recipientName: json['recipientName'] as String? ?? '',
      recipientPhone: json['recipientPhone'] as String? ?? '',
      shippingAddress: json['shippingAddress'] as String? ?? '',
      subtotalAmount: (json['subtotalAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      customerNote: json['customerNote'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
        'shippingAddress': shippingAddress,
        'subtotalAmount': subtotalAmount,
        'discountAmount': discountAmount,
        'shippingFee': shippingFee,
        'finalAmount': finalAmount,
        'customerNote': customerNote,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'orderChannel': orderChannel,
        'paidAt': paidAt?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
      };
}
