import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../models/order.dart';
import '../services/store_domain_api_service.dart';
import '../widgets/common/product_image.dart';

/// Màn hình thông báo đặt hàng thành công & hóa đơn điện tử / mã VietQR
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
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
        title: InkWell(
          onTap: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                color: AppColors.surfaceCard,
                child: const Text(
                  'JOPPE',
                  style: TextStyle(
                    color: AppColors.neonCyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'HOÀN TẤT ĐƠN HÀNG',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.textWhite,
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
            icon: const Icon(Icons.home_outlined, color: AppColors.neonCyan),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thanh tiến trình Step 3
            _buildStepIndicator(),
            const SizedBox(height: 16),

            // Card trạng thái thành công
            _buildSuccessHeader(context),
            const SizedBox(height: 16),

            // Card VNPAY nếu chọn thanh toán VNPAY (Thẻ ATM / QR)
            if (order.paymentMethod == PaymentMethodType.vnpay) ...[
              _buildVnPayCard(context),
              const SizedBox(height: 16),
            ],

            // Card VietQR nếu chọn chuyển khoản QR
            if (order.paymentMethod == PaymentMethodType.vietQr) ...[
              _buildVietQrCard(context),
              const SizedBox(height: 16),
            ],

            // Card thông tin giao nhận & người đặt
            _buildCustomerInfoCard(context),
            const SizedBox(height: 16),

            // Danh sách sản phẩm
            _buildPurchasedItemsCard(),
            const SizedBox(height: 16),

            // Bảng kê chi phí
            _buildPaymentSummaryCard(),
            const SizedBox(height: 24),

            // Nút điều hướng
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderLight, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
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
                      shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                    ),
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
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
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Row(
        children: [
          _buildStepItem('1. GIỎ HÀNG', isCompleted: true),
          const Icon(Icons.arrow_right_alt, color: AppColors.neonCyan, size: 16),
          _buildStepItem('2. THANH TOÁN', isCompleted: true),
          const Icon(Icons.arrow_right_alt, color: AppColors.neonCyan, size: 16),
          _buildStepItem('3. HOÀN TẤT', isActive: true),
        ],
      ),
    );
  }

  Widget _buildStepItem(String title, {bool isActive = false, bool isCompleted = false}) {
    return Expanded(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isActive
              ? AppColors.neonCyan
              : (isCompleted ? AppColors.textWhite : AppColors.textSubtle),
          fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
          fontSize: 10,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.neonCyan, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.neonCyan, width: 2),
            ),
            child: const Icon(Icons.check, color: AppColors.neonCyan, size: 36),
          ),
          const SizedBox(height: 14),
          const Text(
            'ĐẶT HÀNG THÀNH CÔNG!',
            style: TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cảm ơn quý khách đã tin tưởng mua sắm tại JOPPE Store.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: AppColors.primaryDark,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MÃ ĐƠN HÀNG: ',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Flexible(
                  child: Text(
                    order.orderId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVnPayCard(BuildContext context) {
    final vnpayPaymentUrl = order.vnpayPaymentUrl;
    final fallbackQrUrl = order.vnpayQrCodeUrl ??
        StoreDomainApiService().buildVnPayQrUrl(
          paymentUrl: vnpayPaymentUrl ?? 'https://joppe.penguinlab.org/orders/${order.orderId}',
          size: 300,
        );
    final txnRef = order.vnpayTxnRef ?? order.orderId;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: const Color(0xFF005BAA), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF005BAA),
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
                // Container chứa ảnh mã QR VNPAY
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.borderLight, width: 2),
                  ),
                  child: order.vnpayQrCodeBase64 != null && order.vnpayQrCodeBase64!.isNotEmpty
                      ? Image.memory(
                          base64Decode(order.vnpayQrCodeBase64!),
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          fallbackQrUrl,
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
                if (vnpayPaymentUrl != null && vnpayPaymentUrl.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11B22),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(vnpayPaymentUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            await launchUrl(uri);
                          }
                        } catch (_) {
                          await Clipboard.setData(ClipboardData(text: vnpayPaymentUrl));
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF005BAA),
                        side: const BorderSide(color: Color(0xFF005BAA), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vnpayPaymentUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép liên kết thanh toán VNPAY!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 15),
                      label: const Text(
                        'Sao chép liên kết thanh toán',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Thông tin thanh toán VNPAY
                _buildBankRow('Cổng thanh toán', 'VNPAY Gateway (Chính thức)', null, context),
                _buildBankRow('Mã giao dịch (TxnRef)', txnRef, txnRef, context),
                _buildBankRow('Số tiền thanh toán', order.formattedGrandTotal, order.grandTotal.round().toString(), context),
                _buildBankRow('Trạng thái giao dịch', 'Chờ xác nhận qua VNPAY IPN', null, context),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: AppColors.primaryDark,
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user, color: AppColors.neonCyan, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Giao dịch được đối soát tự động qua webhook IPN 24/7 của VNPAY. Đơn hàng sẽ cập nhật trạng thái ngay khi giao dịch thành công.',
                          style: TextStyle(color: AppColors.textWhite, fontSize: 11),
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

  Widget _buildVietQrCard(BuildContext context) {
    final transferMemo = 'JOPPE ${order.orderId}';
    final amountNumber = order.grandTotal.round();
    final qrUrl = 'https://img.vietqr.io/image/970422-0868302123-compact2.png?amount=$amountNumber&addInfo=$transferMemo&accountName=CONG%20TY%20CP%20CONG%20NGHE%20JOPPE';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.primaryBlue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.primaryBlue,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.borderLight, width: 2),
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
                _buildBankRow('Ngân hàng thụ hưởng', 'MB Bank (Quân Đội)', null, context),
                _buildBankRow('Số tài khoản', '0868302123', '0868302123', context),
                _buildBankRow('Tên chủ tài khoản', 'CONG TY CP CONG NGHE JOPPE', null, context),
                _buildBankRow('Số tiền chính xác', order.formattedGrandTotal, amountNumber.toString(), context),
                _buildBankRow('Nội dung chuyển khoản', transferMemo, transferMemo, context),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  color: AppColors.primaryDark,
                  child: const Row(
                    children: [
                      Icon(Icons.bolt, color: AppColors.neonCyan, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hệ thống tự động duyệt đơn trong 30 giây ngay khi nhận được biến động số dư VietQR 24/7.',
                          style: TextStyle(color: AppColors.textWhite, fontSize: 11),
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

  Widget _buildBankRow(String label, String value, String? copyText, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: AppColors.primaryDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (copyText != null) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: copyText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã sao chép: $copyText'),
                          backgroundColor: AppColors.primaryBlue,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.copy, size: 14, color: AppColors.neonCyan),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: AppColors.neonCyan, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'THÔNG TIN GIAO HÀNG & THANH TOÁN',
                  style: TextStyle(
                    color: AppColors.textWhite,
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
          const SizedBox(height: 12),
          _buildInfoRow('Người nhận:', order.customerName),
          _buildInfoRow('Số điện thoại:', order.phoneNumber),
          _buildInfoRow('Email nhận đơn:', order.email),
          _buildInfoRow('Địa chỉ nhận hàng:', order.shippingAddress),
          _buildInfoRow('Vận chuyển:', order.shippingMethod.title),
          _buildInfoRow('Thanh toán:', order.paymentMethod.title),
          if (order.orderNotes != null && order.orderNotes!.isNotEmpty)
            _buildInfoRow('Ghi chú:', order.orderNotes!),
          if (order.isVatRequested) ...[
            const Divider(color: AppColors.borderLight, height: 16),
            const Text(
              'HÓA ĐƠN ĐỎ (VAT):',
              style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 11),
            ),
            _buildInfoRow('Công ty:', order.companyName ?? ''),
            _buildInfoRow('Mã số thuế:', order.taxCode ?? ''),
            _buildInfoRow('Địa chỉ công ty:', order.companyAddress ?? ''),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasedItemsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'DANH SÁCH SẢN PHẨM',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${order.items.length} mặt hàng',
                style: const TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(8),
              color: AppColors.primaryDark,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: ProductImage(
                      imageUrl: item.product.imageUrl,
                      componentType: item.product.componentType,
                      brand: item.product.brand,
                      width: 48,
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.product.brand.toUpperCase()} | Số lượng: ${item.quantity}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.formattedTotalPrice,
                    style: const TextStyle(
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHI TIẾT THANH TOÁN',
            style: TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryLine('Tạm tính:', order.formattedSubtotal),
          _buildSummaryLine('Phí vận chuyển:', order.formattedShippingFee),
          if (order.discountAmount > 0)
            _buildSummaryLine('Mã giảm giá (${order.voucherCode}):', '-${order.formattedDiscountAmount}', isDiscount: true),
          if (order.pointsDiscount > 0)
            _buildSummaryLine('Điểm thưởng (${order.pointsUsed} điểm):', '-${order.formattedPointsDiscount}', isDiscount: true),
          const Divider(color: AppColors.borderLight, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'TỔNG TIỀN THANH TOÁN:',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    order.formattedGrandTotal,
                    style: const TextStyle(
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: isDiscount ? Colors.greenAccent : AppColors.textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
