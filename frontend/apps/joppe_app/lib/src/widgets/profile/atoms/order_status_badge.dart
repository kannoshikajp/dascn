import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Atom: Tag hiển thị trạng thái đơn hàng (DELIVERED, PENDING, CANCELLED, ...)
class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  Color get _color {
    final s = status.toUpperCase();
    if (s == 'DELIVERED') return Colors.green;
    if (s == 'CANCELLED') return AppColors.accentRed;
    if (s == 'PENDING') return Colors.orange;
    return AppColors.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
