import 'receipt_item_model.dart';

class GoodReceiptDetail {
  final String id;
  final String receiptCode;
  final String receiptType;
  final String? supplierId;
  final String? supplierName;
  final String? orderId;
  final String? orderCode;
  final String staffId;
  final String staffName;
  final double totalAmount;
  final String status;
  final DateTime? createdAt;
  final String? note;
  final List<ReceiptItemModel> items;

  const GoodReceiptDetail({
    required this.id,
    required this.receiptCode,
    this.receiptType = 'INBOUND',
    this.supplierId,
    this.supplierName,
    this.orderId,
    this.orderCode,
    required this.staffId,
    required this.staffName,
    required this.totalAmount,
    required this.status,
    this.createdAt,
    this.note,
    required this.items,
  });

  bool get isInbound => receiptType.toUpperCase() == 'INBOUND';
  bool get isOutbound => receiptType.toUpperCase() == 'OUTBOUND';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  factory GoodReceiptDetail.fromJson(Map<String, dynamic> json) {
    return GoodReceiptDetail(
      id: json['id'] as String,
      receiptCode: json['receiptCode'] as String? ?? '',
      receiptType: json['receiptType'] as String? ?? 'INBOUND',
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
      orderId: json['orderId'] as String?,
      orderCode: json['orderCode'] as String?,
      staffId: json['staffId'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      note: json['note'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ReceiptItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'receiptCode': receiptCode,
        'receiptType': receiptType,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'orderId': orderId,
        'orderCode': orderCode,
        'staffId': staffId,
        'staffName': staffName,
        'totalAmount': totalAmount,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
        'note': note,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
