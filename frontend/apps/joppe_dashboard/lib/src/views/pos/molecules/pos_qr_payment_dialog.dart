import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/receipt_printer_helper.dart';
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
  Timer? _countdownTimer;
  int _remainingSeconds = 600; // 10 minutes default Stock Hold TTL
  bool _isPaid = false;
  bool _isExpired = false;
  bool _isManualConfirming = false;
  late OrderDetailModel _currentOrder = widget.order;

  @override
  void initState() {
    super.initState();
    _initTtlCountdown();
    _startPolling();
  }

  void _initTtlCountdown() {
    if (widget.order.paymentExpiresAt != null) {
      final diff = widget.order.paymentExpiresAt!.difference(DateTime.now()).inSeconds;
      _remainingSeconds = diff > 0 ? diff : 0;
    } else {
      _remainingSeconds = 600;
    }

    if (_remainingSeconds <= 0) {
      _isExpired = true;
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _pollingTimer?.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isExpired = true;
        });
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (_isExpired) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final currentOrder = await widget.orderService.getAdminOrderDetail(widget.order.id);
        if (currentOrder.paymentStatus.toUpperCase() == 'PAID') {
          timer.cancel();
          _countdownTimer?.cancel();
          if (mounted) {
            setState(() {
              _isPaid = true;
              _currentOrder = currentOrder;
            });
          }
        }
      } catch (_) {
        // Silently continue polling
      }
    });
  }

  Future<void> _manualConfirm() async {
    final refController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.blue, size: 22),
            SizedBox(width: 8),
            Text('Xác thực thanh toán thủ công', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Để chống thất thoát, vui lòng nhập mã giao dịch ngân hàng hoặc số biên nhận thu tiền mặt:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: refController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Mã tham chiếu / Mã giao dịch (*)',
                  hintText: 'VD: MBBANK-98231, VNPAY-1122...',
                  prefixIcon: Icon(Icons.receipt_long, size: 18),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 4) {
                    return 'Vui lòng nhập tối thiểu 4 ký tự mã giao dịch';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú xác nhận (tùy chọn)',
                  hintText: 'VD: Khách chuyển khoản đúng nội dung',
                  prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy bỏ'),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Xác nhận & Lưu vết'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isManualConfirming = true);
    try {
      OrderDetailModel updated;
      try {
        updated = await widget.orderService.manualPaymentConfirm(
          widget.order.id,
          referenceCode: refController.text.trim(),
          note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        );
      } catch (_) {
        updated = await widget.orderService.updatePaymentStatus(widget.order.id, 'PAID');
      }
      _pollingTimer?.cancel();
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() {
          _isPaid = true;
          _currentOrder = updated;
        });
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

  String _formatTtl(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
      final resolvedUrl = ApiClient.resolveUrl(qrUrl);
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
                    onPressed: () {
                      Navigator.pop(context);
                      if (_isPaid) {
                        widget.onPaymentCompleted();
                      }
                    },
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24),

              if (_isPaid) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
                      const SizedBox(height: 12),
                      const Text(
                        'Thanh toán thành công!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(70),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withAlpha(60)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã đơn hàng: ${_currentOrder.orderCode}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Khách hàng: ${_currentOrder.recipientName} (${_currentOrder.recipientPhone})',
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Tổng tiền thanh toán: ${_formatPrice(_currentOrder.finalAmount)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text('Trạng thái: ', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withAlpha(30),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.green.withAlpha(80)),
                                  ),
                                  child: const Text(
                                    'ĐÃ THANH TOÁN (PAID)',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            if (_currentOrder.manualPaymentRef != null && _currentOrder.manualPaymentRef!.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                'Mã GD đối soát: ${_currentOrder.manualPaymentRef}',
                                style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => printReceipt(context, _currentOrder),
                              icon: const Icon(Icons.print_outlined, size: 18),
                              label: const Text('In hóa đơn', maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(context, true);
                                widget.onPaymentCompleted();
                              },
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                              label: const Text('Tạo đơn tiếp theo', maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // TTL Countdown Chip
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isExpired
                          ? Colors.red.withAlpha(25)
                          : (_remainingSeconds < 60 ? Colors.orange.withAlpha(30) : colorScheme.primaryContainer.withAlpha(80)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isExpired
                            ? Colors.red.withAlpha(120)
                            : (_remainingSeconds < 60 ? Colors.orange : colorScheme.primary.withAlpha(120)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                          size: 14,
                          color: _isExpired ? Colors.red : (_remainingSeconds < 60 ? Colors.orange : colorScheme.primary),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _isExpired
                                ? 'Hết hạn giữ hàng (TTL)'
                                : 'Giữ tồn kho: ${_formatTtl(_remainingSeconds)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isExpired ? Colors.red : (_remainingSeconds < 60 ? Colors.orange : colorScheme.primary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: JoppeSpacing.sm),

                // Backend Generated QR Code (with local fallback)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withAlpha(120)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Opacity(
                          opacity: _isExpired ? 0.2 : 1.0,
                          child: _buildQrCode(qrData, colorScheme),
                        ),
                      ),
                      if (_isExpired)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 36),
                              SizedBox(height: 6),
                              Text(
                                'Mã QR đã hết hạn',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Tồn kho đã được giải phóng',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
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
                    if (!_isExpired) ...[
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
                    ] else ...[
                      const Icon(Icons.info_outline, size: 14, color: Colors.red),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Đã dừng chờ - Vui lòng đóng cửa sổ để tạo lại.',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: JoppeSpacing.md),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isExpired ? null : _openPopupWindow,
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
