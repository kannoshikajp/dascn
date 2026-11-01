import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/web_popup_helper.dart';

/// Molecule: POS Cashier Dialog displaying QR code for customer scan,
/// auto-polling for payment confirmation, and a popup window button.
class PosVnPayQrDialog extends StatefulWidget {
  final OrderDetailModel order;
  final VnPayPaymentModel vnpayInfo;
  final OrderService orderService;
  final VoidCallback onPaymentCompleted;

  const PosVnPayQrDialog({
    super.key,
    required this.order,
    required this.vnpayInfo,
    required this.orderService,
    required this.onPaymentCompleted,
  });

  @override
  State<PosVnPayQrDialog> createState() => _PosVnPayQrDialogState();
}

class _PosVnPayQrDialogState extends State<PosVnPayQrDialog> {
  Timer? _pollingTimer;
  bool _isPaid = false;
  bool _isManualConfirming = false;

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
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final currentOrder = await widget.orderService.getAdminOrderDetail(widget.order.id);
        if (currentOrder.paymentStatus.toUpperCase() == 'PAID') {
          timer.cancel();
          if (mounted) {
            setState(() => _isPaid = true);
            await Future.delayed(const Duration(milliseconds: 600));
            if (mounted) {
              Navigator.pop(context, true);
              widget.onPaymentCompleted();
            }
          }
        }
      } catch (_) {
        // Silently continue polling
      }
    });
  }

  Future<void> _manualConfirm() async {
    setState(() => _isManualConfirming = true);
    try {
      await widget.orderService.updatePaymentStatus(widget.order.id, 'PAID');
      _pollingTimer?.cancel();
      if (mounted) {
        setState(() => _isPaid = true);
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) {
          Navigator.pop(context, true);
          widget.onPaymentCompleted();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isManualConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xác nhận thủ công: $e')),
        );
      }
    }
  }

  void _openPopupWindow() {
    final url = widget.vnpayInfo.paymentUrl;
    if (url.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy liên kết thanh toán VNPAY.')),
        );
      }
      return;
    }
    openPopupWindow(url);
  }

  String _formatPrice(double price) {
    if (price <= 0) return '0 ₫';
    final str = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} ₫';
  }

  Widget _buildQrCode(String qrData, ColorScheme colorScheme) {
    // 1. Prefer Backend-generated QR Code (Base64 data URI or raw base64)
    final base64String = widget.vnpayInfo.qrCodeBase64;
    if (base64String != null && base64String.isNotEmpty) {
      try {
        final cleanBase64 = base64String.contains(',')
            ? base64String.split(',').last
            : base64String;
        final bytes = base64Decode(cleanBase64);
        return Image.memory(
          bytes,
          width: 220,
          height: 220,
          fit: BoxFit.contain,
        );
      } catch (_) {
        // Fallback below
      }
    }

    // 2. Or Backend-generated QR Code Image URL
    final qrUrl = widget.vnpayInfo.qrCodeUrl;
    if (qrUrl != null && qrUrl.isNotEmpty) {
      final resolvedUrl = qrUrl.startsWith('http')
          ? qrUrl
          : '${ApiConstants.defaultBaseUrl}$qrUrl';
      return Image.network(
        resolvedUrl,
        width: 220,
        height: 220,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildLocalQrFallback(qrData),
      );
    }

    // 3. Fallback: Local Client-side Generated QR Code
    return _buildLocalQrFallback(qrData);
  }

  Widget _buildLocalQrFallback(String qrData) {
    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: 220,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final qrData = widget.vnpayInfo.paymentUrl;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(JoppeSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.qr_code_2_rounded, color: colorScheme.onPrimaryContainer, size: 24),
                  ),
                  const SizedBox(width: JoppeSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quét mã VNPAY / VietQR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Đơn hàng: ${widget.order.orderCode}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24),

              if (_isPaid) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                      SizedBox(height: 12),
                      Text('Thanh toán thành công!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                      SizedBox(height: 4),
                      Text('Đơn hàng đã được xác nhận thanh toán.'),
                    ],
                  ),
                ),
              ] else ...[
                // Backend Generated QR Code (with local fallback)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withAlpha(120)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: _buildQrCode(qrData, colorScheme),
                  ),
                ),
                const SizedBox(height: JoppeSpacing.md),

                // Amount Tile
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(70),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Số tiền thanh toán:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        _formatPrice(widget.order.finalAmount),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: JoppeSpacing.md),

                // Live waiting status with spinner
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Đang chờ khách quét mã thanh toán...',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: JoppeSpacing.md),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openPopupWindow,
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('Mở Popup VNPAY', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: JoppeSpacing.xs),
                    IconButton.outlined(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.vnpayInfo.paymentUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép liên kết VNPAY vào bộ nhớ tạm.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Sao chép liên kết thanh toán',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: JoppeSpacing.xs),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isManualConfirming ? null : _manualConfirm,
                        icon: _isManualConfirming
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Xác nhận nhận tiền', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
