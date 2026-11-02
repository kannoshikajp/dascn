import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../models/order.dart';
import '../widgets/order_success/atoms/order_step_indicator.dart';
import '../widgets/order_success/compounds/order_customer_card.dart';
import '../widgets/order_success/compounds/order_items_card.dart';
import '../widgets/order_success/compounds/order_payment_summary_card.dart';
import '../widgets/order_success/compounds/order_success_header.dart';
import '../widgets/order_success/compounds/vietqr_payment_card.dart';
import '../widgets/order_success/compounds/vnpay_payment_card.dart';

/// Polymer: Màn hình thông báo đặt hàng thành công & hóa đơn điện tử / thanh toán
class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        titleSpacing: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
        title: InkWell(
          onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'JOPPE',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'HOÀN TẤT ĐƠN HÀNG',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Về trang chủ JOPPE',
            icon: const Icon(Icons.home_outlined, color: AppColors.primaryBlue),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thanh tiến trình Step 3
                const OrderStepIndicator(),
                const SizedBox(height: 16),

                // Card trạng thái thành công
                OrderSuccessHeader(orderId: order.orderId),
                const SizedBox(height: 16),

                // Card VNPAY nếu chọn thanh toán VNPAY (Thẻ ATM / QR)
                if (order.paymentMethod == PaymentMethodType.vnpay) ...[
                  VnPayPaymentCard(order: order),
                  const SizedBox(height: 16),
                ],

                // Card VietQR nếu chọn chuyển khoản QR
                if (order.paymentMethod == PaymentMethodType.vietQr) ...[
                  VietQrPaymentCard(order: order),
                  const SizedBox(height: 16),
                ],

                // Card thông tin giao nhận & người đặt
                OrderCustomerCard(order: order),
                const SizedBox(height: 16),

                // Danh sách sản phẩm
                OrderItemsCard(order: order),
                const SizedBox(height: 16),

                // Bảng kê chi phí
                OrderPaymentSummaryCard(order: order),
                const SizedBox(height: 24),

                // Nút điều hướng
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderLight, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: order.orderId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã sao chép mã đơn hàng: ${order.orderId}'),
                              backgroundColor: AppColors.primaryBlue,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 15),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('SAO CHÉP MÃ ĐƠN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.textOnAction,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                        ),
                        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'TIẾP TỤC MUA SẮM',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
