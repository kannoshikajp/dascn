import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/order.dart';

/// Compound: Khối thông tin khách hàng, địa chỉ giao nhận và hóa đơn VAT
class OrderCustomerCard extends StatelessWidget {
  final Order order;

  const OrderCustomerCard({super.key, required this.order});

  Widget _buildFieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
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
          const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: AppColors.primaryBlue, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'THÔNG TIN GIAO HÀNG & THANH TOÁN',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
          _buildFieldRow('Người nhận:', order.customerName),
          _buildFieldRow('Số điện thoại:', order.phoneNumber),
          _buildFieldRow('Email nhận đơn:', order.email),
          _buildFieldRow('Địa chỉ nhận hàng:', order.shippingAddress),
          _buildFieldRow('Vận chuyển:', order.shippingMethod.title),
          _buildFieldRow('Thanh toán:', order.paymentMethod.title),
          if (order.orderNotes != null && order.orderNotes!.isNotEmpty)
            _buildFieldRow('Ghi chú:', order.orderNotes!),
          if (order.isVatRequested) ...[
            const Divider(color: AppColors.borderLight, height: 16),
            const Text(
              'HÓA ĐƠN ĐỎ (VAT):',
              style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11),
            ),
            const SizedBox(height: 6),
            _buildFieldRow('Công ty:', order.companyName ?? ''),
            _buildFieldRow('Mã số thuế:', order.taxCode ?? ''),
            _buildFieldRow('Địa chỉ công ty:', order.companyAddress ?? ''),
          ],
        ],
      ),
    );
  }
}
