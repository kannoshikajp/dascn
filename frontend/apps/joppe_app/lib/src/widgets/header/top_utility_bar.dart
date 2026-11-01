import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Thanh tiện ích trên cùng (Top Utility Bar) với nền xanh sáng và góc vuông tuyệt đối
class TopUtilityBar extends StatelessWidget {
  const TopUtilityBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bên trái: Slogan & Nhãn hệ thống
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.desktop_windows_outlined,
                  size: 14,
                  color: AppColors.textOnAction,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Mạng mua sắm PC & Gaming Gear',
                  style: TextStyle(
                    color: AppColors.textOnAction,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 16),
                _buildTextItem('Tập Tin'),
                _buildTextItem('Xem'),
                _buildTextItem('Công Cụ'),
              ],
            ),
            const SizedBox(width: 24),
            // Bên phải: Thông tin liên hệ & Tiện ích
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildContactItem(
                  icon: Icons.phone_in_talk,
                  text: '086 830 2123',
                ),
                const SizedBox(width: 14),
                _buildContactItem(
                  icon: Icons.email_outlined,
                  text: 'cskh@tncstore.vn',
                ),
                const SizedBox(width: 14),
                _buildContactItem(
                  icon: Icons.grid_view_sharp,
                  text: 'Tất cả sản phẩm',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextItem(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textOnAction.withValues(alpha: 0.85),
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildContactItem({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textOnAction),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textOnAction,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
