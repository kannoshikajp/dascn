import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/user_account.dart';
import '../atoms/role_badge.dart';
import '../atoms/user_avatar.dart';

/// Compound: Thẻ thông tin cá nhân người dùng (Bo góc 20px, ẩn ROLE_CUSTOMER)
class ProfileUserCard extends StatelessWidget {
  final UserAccount user;

  const ProfileUserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(avatarUrl: user.avatarUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    RoleBadge(role: user.role),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                if (user.phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'SĐT: ${user.phoneNumber}',
                    style: const TextStyle(color: AppColors.textSubtle, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
