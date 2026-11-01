import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

enum PosPaymentMethod {
  cash,
  qrTransfer,
  card,
}

/// Molecule: POS Cashier checkout summary with prominent "Total Money to Pay" display and charge action.
class PosCheckoutPanel extends StatelessWidget {
  final double subtotal;
  final double shippingFee;
  final PosPaymentMethod paymentMethod;
  final ValueChanged<PosPaymentMethod> onPaymentMethodChanged;
  final bool isCounterPickup;
  final ValueChanged<bool> onDeliveryPresetChanged;
  final VoidCallback onCheckout;
  final bool isSubmitting;
  final int totalItems;

  const PosCheckoutPanel({
    super.key,
    required this.subtotal,
    required this.shippingFee,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
    required this.isCounterPickup,
    required this.onDeliveryPresetChanged,
    required this.onCheckout,
    this.isSubmitting = false,
    required this.totalItems,
  });

  double get totalPayable => subtotal + (isCounterPickup ? 0 : shippingFee);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(JoppeSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Type / Delivery preset
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hình thức nhận hàng:', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  segments: const [
                    ButtonSegment(value: true, label: Text('Tại quầy (0 ₫)', style: TextStyle(fontSize: 10))),
                    ButtonSegment(value: false, label: Text('Giao hàng', style: TextStyle(fontSize: 10))),
                  ],
                  selected: {isCounterPickup},
                  onSelectionChanged: (s) => onDeliveryPresetChanged(s.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: JoppeSpacing.sm),

          // Payment method selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phương thức thanh toán:', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<PosPaymentMethod>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: PosPaymentMethod.cash,
                      label: Text('Tiền mặt', style: TextStyle(fontSize: 10)),
                    ),
                    ButtonSegment(
                      value: PosPaymentMethod.qrTransfer,
                      label: Text('QR/CK', style: TextStyle(fontSize: 10)),
                    ),
                    ButtonSegment(
                      value: PosPaymentMethod.card,
                      label: Text('Thẻ POS', style: TextStyle(fontSize: 10)),
                    ),
                  ],
                  selected: {paymentMethod},
                  onSelectionChanged: (s) => onPaymentMethodChanged(s.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: JoppeSpacing.sm),

          // Calculation breakdown lines
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tạm tính ($totalItems món):', style: theme.textTheme.bodySmall),
              Text(_formatPrice(subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          if (!isCounterPickup) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Phí vận chuyển:', style: theme.textTheme.bodySmall),
                Text('+ ${_formatPrice(shippingFee)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
          const SizedBox(height: JoppeSpacing.md),

          // THE HERO TOTAL MONEY TO PAY CARD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.md, vertical: JoppeSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'TỔNG TIỀN PHẢI TRẢ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withAlpha(200),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatPrice(totalPayable),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onPrimaryContainer,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: JoppeSpacing.md),

          // Primary Checkout Button
          FilledButton.icon(
            onPressed: (totalItems == 0 || isSubmitting) ? null : onCheckout,
            icon: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.point_of_sale_rounded),
            label: Text(
              isSubmitting
                  ? 'Đang xử lý...'
                  : 'Thanh toán ${_formatPrice(totalPayable)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: JoppeSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
