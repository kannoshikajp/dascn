import 'cart_item.dart';
import 'product.dart';

/// Các phương thức vận chuyển hỗ trợ
enum ShippingMethod {
  standard,
  express,
  storePickup,
}

extension ShippingMethodExtension on ShippingMethod {
  String get title {
    switch (this) {
      case ShippingMethod.standard:
        return 'Giao hàng tiêu chuẩn (2 - 3 ngày)';
      case ShippingMethod.express:
        return 'Hỏa tốc 2 Giờ (Nội thành)';
      case ShippingMethod.storePickup:
        return 'Nhận trực tiếp tại Showroom JOPPE';
    }
  }

  String get description {
    switch (this) {
      case ShippingMethod.standard:
        return 'Miễn phí vận chuyển cho đơn hàng từ 2.000.000 ₫';
      case ShippingMethod.express:
        return 'Giao ngay trong 2 giờ bằng dịch vụ hỏa tốc bảo đảm';
      case ShippingMethod.storePickup:
        return 'Giữ hàng tại showroom, kiểm tra và lắp ráp miễn phí';
    }
  }

  double calculateFee(double subtotal) {
    switch (this) {
      case ShippingMethod.standard:
        return subtotal >= 2000000 ? 0.0 : 30000.0;
      case ShippingMethod.express:
        return 60000.0;
      case ShippingMethod.storePickup:
        return 0.0;
    }
  }
}

/// Các phương thức thanh toán hỗ trợ
enum PaymentMethodType {
  vietQr,
  cod,
  momo,
  vnpay,
  creditCard,
  installment,
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  String get title {
    switch (this) {
      case PaymentMethodType.vietQr:
        return 'Chuyển khoản QR (VietQR / Napas 247)';
      case PaymentMethodType.cod:
        return 'Thanh toán khi nhận hàng (COD)';
      case PaymentMethodType.momo:
        return 'Ví điện tử MoMo';
      case PaymentMethodType.vnpay:
        return 'Cổng VNPAY (Thẻ ATM / QR)';
      case PaymentMethodType.creditCard:
        return 'Thẻ Quốc tế (Visa / MasterCard / JCB)';
      case PaymentMethodType.installment:
        return 'Trả góp 0% (Thẻ tín dụng & Tài chính)';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethodType.vietQr:
        return 'Tạo mã QR tự động điền số tiền và mã đơn, khớp lệnh tức thì 24/7';
      case PaymentMethodType.cod:
        return 'Kiểm tra hàng trước khi thanh toán tiền mặt cho shipper';
      case PaymentMethodType.momo:
        return 'Mở ứng dụng MoMo để quét mã thanh toán không tiền mặt';
      case PaymentMethodType.vnpay:
        return 'Hỗ trợ quét qua hơn 30 ứng dụng ngân hàng và ví điện tử';
      case PaymentMethodType.creditCard:
        return 'Bảo mật chuẩn quốc tế 3D Secure 256-bit SSL';
      case PaymentMethodType.installment:
        return 'Hỗ trợ kỳ hạn linh hoạt 3 - 6 - 12 tháng với lãi suất 0%';
    }
  }

  String? get badgeText {
    switch (this) {
      case PaymentMethodType.vietQr:
        return 'KHUYÊN DÙNG';
      case PaymentMethodType.installment:
        return '0% LÃI SUẤT';
      default:
        return null;
    }
  }
}

/// Model Đơn Hàng Hoàn Chỉnh sau khi thanh toán
class Order {
  final String orderId;
  final List<CartItem> items;
  final String customerName;
  final String phoneNumber;
  final String email;
  final String shippingAddress;
  final ShippingMethod shippingMethod;
  final PaymentMethodType paymentMethod;
  final String? orderNotes;
  final double subtotal;
  final double shippingFee;
  final String? voucherCode;
  final double discountAmount;
  final int pointsUsed;
  final double pointsDiscount;
  final double grandTotal;
  final bool isVatRequested;
  final String? companyName;
  final String? taxCode;
  final String? companyAddress;
  final DateTime createdAt;
  final String orderStatus;
  final String? vnpayPaymentUrl;
  final String? vnpayQrCodeUrl;
  final String? vnpayPaymentId;
  final String? vnpayTxnRef;
  final String? vnpayQrCodeBase64;

  Order({
    required this.orderId,
    required this.items,
    required this.customerName,
    required this.phoneNumber,
    required this.email,
    required this.shippingAddress,
    required this.shippingMethod,
    required this.paymentMethod,
    this.orderNotes,
    required this.subtotal,
    required this.shippingFee,
    this.voucherCode,
    this.discountAmount = 0.0,
    this.pointsUsed = 0,
    this.pointsDiscount = 0.0,
    required this.grandTotal,
    this.isVatRequested = false,
    this.companyName,
    this.taxCode,
    this.companyAddress,
    DateTime? createdAt,
    this.orderStatus = 'Đã đặt hàng',
    this.vnpayPaymentUrl,
    this.vnpayQrCodeUrl,
    this.vnpayPaymentId,
    this.vnpayTxnRef,
    this.vnpayQrCodeBase64,
  }) : createdAt = createdAt ?? DateTime.now();

  String get formattedSubtotal => Product.formatVnd(subtotal);
  String get formattedShippingFee => shippingFee == 0 ? 'MIỄN PHÍ' : Product.formatVnd(shippingFee);
  String get formattedDiscountAmount => Product.formatVnd(discountAmount);
  String get formattedPointsDiscount => Product.formatVnd(pointsDiscount);
  String get formattedGrandTotal => Product.formatVnd(grandTotal);

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'items': items.map((i) => i.toJson()).toList(),
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'email': email,
      'shippingAddress': shippingAddress,
      'shippingMethod': shippingMethod.name,
      'paymentMethod': paymentMethod.name,
      'orderNotes': orderNotes,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'voucherCode': voucherCode,
      'discountAmount': discountAmount,
      'pointsUsed': pointsUsed,
      'pointsDiscount': pointsDiscount,
      'grandTotal': grandTotal,
      'isVatRequested': isVatRequested,
      'companyName': companyName,
      'taxCode': taxCode,
      'companyAddress': companyAddress,
      'createdAt': createdAt.toIso8601String(),
      'orderStatus': orderStatus,
      'vnpayPaymentUrl': vnpayPaymentUrl,
      'vnpayQrCodeUrl': vnpayQrCodeUrl,
      'vnpayPaymentId': vnpayPaymentId,
      'vnpayTxnRef': vnpayTxnRef,
      'vnpayQrCodeBase64': vnpayQrCodeBase64,
    };
  }
}
