class GoodReceiptSummary {
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
  final int totalItems;
  final String status;
  final DateTime? createdAt;
  final String? note;

  const GoodReceiptSummary({
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
    required this.totalItems,
    required this.status,
    this.createdAt,
    this.note,
  });

  bool get isInbound => receiptType.toUpperCase() == 'INBOUND';
  bool get isOutbound => receiptType.toUpperCase() == 'OUTBOUND';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  factory GoodReceiptSummary.fromJson(Map<String, dynamic> json) {
    return GoodReceiptSummary(
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
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'DRAFT',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      note: json['note'] as String?,
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
        'totalItems': totalItems,
        'status': status,
        'createdAt': createdAt?.toIso8601String(),
        'note': note,
      };
}
