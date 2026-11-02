import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joppe_core/joppe_core.dart' as core;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order.dart';
import '../../../services/app_api_client.dart';
import '../atoms/order_info_row.dart';

/// Compound: Thẻ thanh toán qua cổng VNPAY & Mã VNPAY-QR
/// Tự động thăm dò (auto-poll) trạng thái thanh toán và chuyển trạng thái hoàn tất
class VnPayPaymentCard extends StatefulWidget {
  final Order order;
  final VoidCallback? onPaymentSuccess;

  const VnPayPaymentCard({
    super.key,
    required this.order,
    this.onPaymentSuccess,
  });

  @override
  State<VnPayPaymentCard> createState() => _VnPayPaymentCardState();
}

class _VnPayPaymentCardState extends State<VnPayPaymentCard> {
  Timer? _pollingTimer;
  bool _isPaid = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkPaymentStatus(silent: true);
    });
  }

  Future<void> _checkPaymentStatus({bool silent = false}) async {
    if (!mounted || _isPaid) return;
    if (!silent) {
      setState(() => _isChecking = true);
    }

    try {
      final vnPayService = core.VnPayService(AppApiClient.instance);
      final res = await vnPayService.checkPaymentStatus(
        orderCode: widget.order.orderId,
        txnRef: widget.order.vnpayTxnRef,
      );

      if (res['isPaid'] == true && mounted) {
        _pollingTimer?.cancel();
        setState(() {
          _isPaid = true;
          _isChecking = false;
        });
        widget.onPaymentSuccess?.call();
      } else if (!silent && mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hệ thống đang chờ nhận tiền từ VNPAY... Vui lòng thử lại sau vài giây.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vnPayService = core.VnPayService(AppApiClient.instance);

    final bool hasValidSignature = widget.order.vnpayPaymentUrl != null &&
        widget.order.vnpayPaymentUrl!.trim().isNotEmpty &&
        widget.order.vnpayPaymentUrl!.contains('vnp_SecureHash=');

    final String paymentUrl = hasValidSignature
        ? widget.order.vnpayPaymentUrl!.trim()
        : vnPayService.buildFallbackPaymentUrl(
            orderCode: widget.order.orderId,
            amount: widget.order.grandTotal,
            txnRef: widget.order.vnpayTxnRef,
          );

    final String txnRef = widget.order.vnpayTxnRef ??
        '${widget.order.orderId}_${DateTime.now().millisecondsSinceEpoch % 1000000}';

    final String qrImageUrl = (widget.order.vnpayQrCodeUrl != null &&
            widget.order.vnpayQrCodeUrl!.trim().isNotEmpty)
        ? widget.order.vnpayQrCodeUrl!.trim()
        : vnPayService.buildQrUrl(paymentUrl: paymentUrl, size: 300);

    final qrBytes = (widget.order.vnpayQrCodeBase64 != null &&
            widget.order.vnpayQrCodeBase64!.isNotEmpty)
        ? core.VnPayPaymentModel(
            paymentId: widget.order.vnpayPaymentId ?? '',
            paymentUrl: paymentUrl,
            orderCode: widget.order.orderId,
            txnRef: txnRef,
            amount: widget.order.grandTotal,
            qrCodeBase64: widget.order.vnpayQrCodeBase64,
          ).qrBytes
        : null;

    final headerColor = _isPaid ? const Color(0xFF16A34A) : const Color(0xFF005BAA);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: headerColor.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: headerColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_isPaid ? Icons.check_circle : Icons.qr_code_scanner,
                    color: AppColors.textOnAction, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isPaid
                        ? 'THANH TOÁN VNPAY THÀNH CÔNG'
                        : 'THANH TOÁN QUA CỔNG VNPAY & MÃ VNPAY-QR',
                    style: const TextStyle(
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
                  _isPaid ? 'ĐÃ HOÀN TẤT' : 'CHÍNH THỨC',
                  style: const TextStyle(
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
                if (_isPaid) ...[
                  // Giao diện hoàn tất thanh toán
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 64),
                        const SizedBox(height: 12),
                        const Text(
                          'THANH TOÁN THÀNH CÔNG!',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hệ thống VNPAY đã xác nhận thanh toán đơn hàng ${widget.order.orderId}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Số tiền: ${widget.order.formattedGrandTotal}',
                          style: const TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
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
                                    style: TextStyle(
                                        color: Color(0xFF005BAA),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
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
                              const SnackBar(
                                  content: Text('Đã sao chép liên kết thanh toán VNPAY vào bộ nhớ tạm!')),
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
                  const SizedBox(height: 8),

                  // Nút kiểm tra trạng thái thanh toán thủ công
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: _isChecking ? null : () => _checkPaymentStatus(silent: false),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                            )
                          : const Icon(Icons.sync, size: 16),
                      label: Text(
                        _isChecking ? 'Đang kiểm tra giao dịch...' : 'Tôi đã hoàn tất thanh toán (Kiểm tra ngay)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Bảng thông tin thanh toán VNPAY
                const OrderInfoRow(label: 'Cổng thanh toán', value: 'VNPAY Gateway (Chính thức)'),
                OrderInfoRow(
                  label: 'Mã giao dịch (TxnRef)',
                  value: txnRef,
                  copyText: txnRef,
                  isMonospace: true,
                ),
                OrderInfoRow(
                  label: 'Số tiền thanh toán',
                  value: widget.order.formattedGrandTotal,
                  copyText: widget.order.grandTotal.round().toString(),
                ),
                OrderInfoRow(
                  label: 'Trạng thái giao dịch',
                  value: _isPaid ? 'ĐÃ THANH TOÁN THÀNH CÔNG' : 'Chờ xác nhận qua VNPAY IPN',
                ),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isPaid ? Icons.check_circle : Icons.verified_user,
                        color: _isPaid ? const Color(0xFF16A34A) : AppColors.primaryBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isPaid
                              ? 'Giao dịch đã được ghi nhận. Đơn hàng đang được chuẩn bị để bàn giao cho đơn vị vận chuyển.'
                              : 'Giao dịch được đối soát tự động qua webhook IPN 24/7 của VNPAY. Đơn hàng sẽ cập nhật trạng thái ngay khi giao dịch thành công.',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
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
