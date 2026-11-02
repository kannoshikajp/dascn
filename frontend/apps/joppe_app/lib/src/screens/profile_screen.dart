import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/profile/atoms/profile_action_tile.dart';
import '../widgets/profile/compounds/address_book_sheet.dart';
import '../widgets/profile/compounds/change_password_dialog.dart';
import '../widgets/profile/compounds/order_history_sheet.dart';
import '../widgets/profile/compounds/profile_stats_card.dart';
import '../widgets/profile/compounds/profile_unauthenticated_view.dart';
import '../widgets/profile/compounds/profile_user_card.dart';
import '../widgets/profile/compounds/saved_pc_builds_sheet.dart';

/// Polymer: Màn hình Hồ Sơ & Quản Lý Tài Khoản Người Dùng Joppe
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'XÁC NHẬN ĐĂNG XUẤT',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản trên thiết bị này?',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('HỦY', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
              foregroundColor: AppColors.textOnAction,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _authService.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã đăng xuất khỏi tài khoản.'),
                  backgroundColor: AppColors.surfaceCard,
                ),
              );
            },
            child: const Text('ĐĂNG XUẤT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            Icon(Icons.manage_accounts, color: AppColors.primaryBlue, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'TÀI KHOẢN CÁ NHÂN',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Trang chủ JOPPE',
            icon: const Icon(Icons.home_outlined, color: AppColors.primaryBlue),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: user == null
            ? const ProfileUnauthenticatedView()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfileUserCard(user: user),
                        const SizedBox(height: 12),
                        ProfileStatsCard(rewardPoints: user.rewardPoints),
                        const SizedBox(height: 16),
                        ProfileActionTile(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Lịch sử mua hàng',
                          subtitle: 'Xem danh sách và theo dõi trạng thái đơn hàng',
                          onTap: () => OrderHistorySheet.show(context),
                        ),
                        ProfileActionTile(
                          icon: Icons.computer,
                          title: 'Cấu hình PC đã lưu',
                          subtitle: 'Quản lý các cấu hình máy đã build và lưu',
                          onTap: () => SavedPcBuildsSheet.show(context),
                        ),
                        ProfileActionTile(
                          icon: Icons.location_on_outlined,
                          title: 'Sổ địa chỉ nhận hàng',
                          subtitle: 'Địa chỉ giao nhận hàng và thông tin liên hệ',
                          onTap: () => AddressBookSheet.show(context),
                        ),
                        ProfileActionTile(
                          icon: Icons.lock_reset,
                          title: 'Bảo mật & Đổi mật khẩu',
                          subtitle: 'Cập nhật mật khẩu và bảo vệ tài khoản',
                          onTap: () => ChangePasswordDialog.show(context),
                        ),
                        const ProfileActionTile(
                          icon: Icons.support_agent_outlined,
                          title: 'Yêu cầu bảo hành & Hỗ trợ kỹ thuật',
                          subtitle: 'Tra cứu bảo hành và liên hệ kỹ thuật',
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentRed,
                            side: BorderSide(color: AppColors.accentRed.withValues(alpha: 0.4), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text(
                            'ĐĂNG XUẤT',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, letterSpacing: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
