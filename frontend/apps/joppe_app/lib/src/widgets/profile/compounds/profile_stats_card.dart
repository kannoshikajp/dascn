import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../atoms/profile_stat_col.dart';

/// Compound: Thẻ thống kê điểm thưởng & Hạng thành viên
class ProfileStatsCard extends StatelessWidget {
  final int rewardPoints;

  const ProfileStatsCard({super.key, required this.rewardPoints});

  static String getMembershipTier(int points) {
    if (points >= 2000) return 'Kim Cương';
    if (points >= 1000) return 'Bạch Kim';
    if (points >= 500) return 'Vàng';
    if (points >= 100) return 'Bạc';
    return 'Thành viên';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ProfileStatCol(
            label: 'ĐIỂM THƯỞNG',
            value: '$rewardPoints PTS',
            valueColor: AppColors.primaryBlue,
          ),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          ProfileStatCol(
            label: 'HẠNG THÀNH VIÊN',
            value: getMembershipTier(rewardPoints),
            valueColor: AppColors.primaryBlue,
          ),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          const ProfileStatCol(
            label: 'ƯU ĐÃI',
            value: 'Miễn phí Ship',
            valueColor: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
