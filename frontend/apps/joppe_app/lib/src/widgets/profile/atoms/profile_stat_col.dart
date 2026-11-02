import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Atom: Cột hiển thị một chỉ số thống kê (Điểm thưởng, Hạng, Ưu đãi)
class ProfileStatCol extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const ProfileStatCol({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSubtle,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
