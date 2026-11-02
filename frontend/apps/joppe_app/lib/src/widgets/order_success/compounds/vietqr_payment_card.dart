import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order.dart';
import '../atoms/order_info_row.dart';

/// Compound: Thẻ chuyển khoản qua mã VietQR (Napas 247)
class VietQrPaymentCard extends StatelessWidget {
  final Order order;

  const VietQrPaymentCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final transferMemo = 'JOPPE ${order.orderId}';
    final amountNumber = order.grandTotal.round();
    final qrUrl = 'https://img.vietqr.io/image/970422-0868302123-compact2.png?amount=$amountNumber&addInfo=$transferMemo&accountName=CONG%20TY%20CP%20CONG%20NGHE%20JOPPE';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.qr_code_scanner, color: AppColors.textOnAction, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QUÉT MÃ VIETQR ĐỂ HOÀN TẤT THANH TOÁN',
                    style: TextStyle(
                      color: AppColors.textOnAction,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Container chứa ảnh mã QR
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight, width: 1.5),
                  ),
                  child: Image.network(
                    qrUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2, size: 64, color: AppColors.primaryDark),
                          SizedBox(height: 8),
                          Text(
                            'Quét mã VietQR',
                            style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Mở bất kỳ ứng dụng Ngân hàng hoặc Ví điện tử để quét mã',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Thông tin chuyển khoản chi tiết
                const OrderInfoRow(label: 'Ngân hàng thụ hưởng', value: 'MB Bank (Quân Đội)'),
                const OrderInfoRow(label: 'Số tài khoản', value: '0868302123', copyText: '0868302123', isMonospace: true),
                const OrderInfoRow(label: 'Tên chủ tài khoản', value: 'CONG TY CP CONG NGHE JOPPE'),
                OrderInfoRow(label: 'Số tiền chính xác', value: order.formattedGrandTotal, copyText: amountNumber.toString()),
                OrderInfoRow(label: 'Nội dung chuyển khoản', value: transferMemo, copyText: transferMemo, isMonospace: true),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight, width: 0.8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.primaryBlue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hệ thống tự động duyệt đơn trong 30 giây ngay khi nhận được biến động số dư VietQR 24/7.',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
