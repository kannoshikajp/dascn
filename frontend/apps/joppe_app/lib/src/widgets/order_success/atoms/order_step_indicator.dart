import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Atom: Thanh chỉ báo các bước tiến trình đặt hàng
class OrderStepIndicator extends StatelessWidget {
  const OrderStepIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: const Row(
        children: [
          _StepItem(title: '1. GIỎ HÀNG', isCompleted: true),
          Icon(Icons.arrow_right_alt, color: AppColors.primaryBlue, size: 16),
          _StepItem(title: '2. THANH TOÁN', isCompleted: true),
          Icon(Icons.arrow_right_alt, color: AppColors.primaryBlue, size: 16),
          _StepItem(title: '3. HOÀN TẤT', isActive: true),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool isCompleted;

  const _StepItem({
    required this.title,
    this.isActive = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isActive
              ? AppColors.primaryBlue
              : (isCompleted ? AppColors.textPrimary : AppColors.textSubtle),
          fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
          fontSize: 10,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
