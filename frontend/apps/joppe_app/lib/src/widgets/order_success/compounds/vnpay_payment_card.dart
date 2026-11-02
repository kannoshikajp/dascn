import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joppe_core/joppe_core.dart' as core;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order.dart';
import '../../../services/app_api_client.dart';
import '../atoms/order_info_row.dart';

/// Compound: Thẻ thanh toán qua cổng VNPAY & Mã VNPAY-QR
/// Sử dụng trực tiếp joppe_core.VnPayService và joppe_core.VnPayPaymentModel
class VnPayPaymentCard extends StatelessWidget {
  final Order order;

  const VnPayPaymentCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final vnPayService = core.VnPayService(AppApiClient.instance);

    // Xác định URL cổng thanh toán VNPAY hợp lệ (luôn trỏ về cổng vnpay, tuyệt đối không dùng api/orders)
    final bool hasValidSignature = order.vnpayPaymentUrl != null &&
        order.vnpayPaymentUrl!.trim().isNotEmpty &&
        order.vnpayPaymentUrl!.contains('vnp_SecureHash=');

    final String paymentUrl = hasValidSignature
        ? order.vnpayPaymentUrl!.trim()
        : vnPayService.buildFallbackPaymentUrl(
            orderCode: order.orderId,
            amount: order.grandTotal,
            txnRef: order.vnpayTxnRef,
          );

    final String txnRef = order.vnpayTxnRef ?? '${order.orderId}_${DateTime.now().millisecondsSinceEpoch % 1000000}';

    // Đường dẫn ảnh mã QR tạo từ API Backend với paymentUrl chuẩn cổng VNPAY
    final String qrImageUrl = (order.vnpayQrCodeUrl != null && order.vnpayQrCodeUrl!.trim().isNotEmpty)
        ? order.vnpayQrCodeUrl!.trim()
        : vnPayService.buildQrUrl(paymentUrl: paymentUrl, size: 300);

    // Dữ liệu ảnh Base64 nếu có từ joppe_core model
    final qrBytes = (order.vnpayQrCodeBase64 != null && order.vnpayQrCodeBase64!.isNotEmpty)
        ? core.VnPayPaymentModel(
            paymentId: order.vnpayPaymentId ?? '',
            paymentUrl: paymentUrl,
            orderCode: order.orderId,
            txnRef: txnRef,
            amount: order.grandTotal,
            qrCodeBase64: order.vnpayQrCodeBase64,
          ).qrBytes
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF005BAA).withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005BAA).withValues(alpha: 0.06),
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
              color: Color(0xFF005BAA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Icon(Icons.qr_code_scanner, color: AppColors.textOnAction, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'THANH TOÁN QUA CỔNG VNPAY & MÃ VNPAY-QR',
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
                Text(
                  'CHÍNH THỨC',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Khung hiển thị ảnh mã QR VNPAY
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight, width: 1.5),
                  ),
                  child: qrBytes != null
                      ? Image.memory(
                          qrBytes,
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          qrImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.qr_code_2, size: 64, color: Color(0xFF005BAA)),
                                SizedBox(height: 8),
                                Text(
                                  'Mã VNPAY-QR',
                                  style: TextStyle(color: Color(0xFF005BAA), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Quét bằng ứng dụng Ngân hàng (VCB, BIDV, VietinBank, Agribank, MB...) hoặc Ví điện tử VNPAY',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Nút mở cổng thanh toán VNPAY trực tiếp
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11B22),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      try {
                        final uri = Uri.parse(paymentUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          await launchUrl(uri);
                        }
                      } catch (_) {
                        await Clipboard.setData(ClipboardData(text: paymentUrl));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã sao chép liên kết thanh toán VNPAY vào bộ nhớ tạm!')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text(
                      'MỞ CỔNG THANH TOÁN VNPAY',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Nút sao chép liên kết thanh toán
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: paymentUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã sao chép liên kết thanh toán VNPAY!')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text(
                      'Sao chép liên kết thanh toán',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Bảng thông tin thanh toán VNPAY
                const OrderInfoRow(label: 'Cổng thanh toán', value: 'VNPAY Gateway (Chính thức)'),
                OrderInfoRow(label: 'Mã giao dịch (TxnRef)', value: txnRef, copyText: txnRef, isMonospace: true),
                OrderInfoRow(label: 'Số tiền thanh toán', value: order.formattedGrandTotal, copyText: order.grandTotal.round().toString()),
                const OrderInfoRow(label: 'Trạng thái giao dịch', value: 'Chờ xác nhận qua VNPAY IPN'),

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
                      Icon(Icons.verified_user, color: AppColors.primaryBlue, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Giao dịch được đối soát tự động qua webhook IPN 24/7 của VNPAY. Đơn hàng sẽ cập nhật trạng thái ngay khi giao dịch thành công.',
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
