import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Atom: Huy hiệu phân quyền người dùng (Ẩn với khách hàng ROLE_CUSTOMER)
class RoleBadge extends StatelessWidget {
  final String? role;

  const RoleBadge({super.key, this.role});

  static bool shouldShow(String? role) {
    if (role == null || role.trim().isEmpty) return false;
    final r = role.toUpperCase();
    if (r == 'ROLE_CUSTOMER' || r == 'KHÁCH HÀNG' || r == 'CUSTOMER' || r.contains('CUSTOMER')) {
      return false;
    }
    return true;
  }

  static String formatName(String role) {
    switch (role.toUpperCase()) {
      case 'ROLE_ADMIN':
        return 'Quản trị viên';
      case 'ROLE_STAFF':
        return 'Nhân viên';
      default:
        return role.replaceAll('ROLE_', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(role)) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        formatName(role!),
        style: const TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
