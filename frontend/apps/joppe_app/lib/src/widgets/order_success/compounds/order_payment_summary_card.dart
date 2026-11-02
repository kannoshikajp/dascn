import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order.dart';

/// Compound: Khối tổng kết chi phí thanh toán đơn hàng
class OrderPaymentSummaryCard extends StatelessWidget {
  final Order order;

  const OrderPaymentSummaryCard({super.key, required this.order});

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
              color: isDiscount ? AppColors.accentRed : AppColors.textPrimary,
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHI TIẾT THANH TOÁN',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryLine('Tạm tính:', order.formattedSubtotal),
          _buildSummaryLine('Phí vận chuyển:', order.formattedShippingFee),
          if (order.discountAmount > 0)
            _buildSummaryLine(
              'Mã giảm giá (${order.voucherCode}):',
              '-${order.formattedDiscountAmount}',
              isDiscount: true,
            ),
          if (order.pointsDiscount > 0)
            _buildSummaryLine(
              'Điểm thưởng (${order.pointsUsed} điểm):',
              '-${order.formattedPointsDiscount}',
              isDiscount: true,
            ),
          const Divider(color: AppColors.borderLight, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'TỔNG TIỀN THANH TOÁN:',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
                      color: AppColors.primaryBlue,
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
}
