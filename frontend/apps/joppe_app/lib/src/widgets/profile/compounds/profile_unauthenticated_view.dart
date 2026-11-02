import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../screens/auth_screen.dart';

/// Compound: View hiển thị khi người dùng chưa đăng nhập
class ProfileUnauthenticatedView extends StatelessWidget {
  const ProfileUnauthenticatedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_off_outlined, color: AppColors.primaryBlue, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'CHƯA ĐĂNG NHẬP',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng đăng nhập để theo dõi đơn hàng, cấu hình PC và nhận ưu đãi tích điểm.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.textOnAction,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen(initialIsLogin: true)),
                );
              },
              child: const Text(
                'ĐĂNG NHẬP / ĐĂNG KÝ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
