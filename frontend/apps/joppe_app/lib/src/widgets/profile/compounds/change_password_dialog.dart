import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';

/// Compound: Hộp thoại đổi mật khẩu tài khoản
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentPass = _currentPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (currentPass.isEmpty || newPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ mật khẩu.'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }
    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không trùng khớp.'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await AuthService().changePassword(
      currentPassword: currentPass,
      newPassword: newPass,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.isSuccess ? AppColors.primaryBlue : AppColors.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.lock_reset, color: AppColors.primaryBlue, size: 20),
          SizedBox(width: 8),
          Text(
            'ĐỔI MẬT KHẨU TÀI KHOẢN',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới để bảo vệ tài khoản.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _currentPassController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại *',
                labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.searchFieldBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _newPassController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới (tối thiểu 6 ký tự) *',
                labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.searchFieldBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPassController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới *',
                labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AppColors.searchFieldBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('HỦY', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.textOnAction,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnAction),
                )
              : const Text('LƯU MẬT KHẨU'),
        ),
      ],
    );
  }
}
