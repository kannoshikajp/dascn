import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';

/// Màn hình Đăng Nhập & Đăng Ký tài khoản chuẩn phong cách Boxy Cyberpunk Joppe
class AuthScreen extends StatefulWidget {
  /// Mặc định hiển thị tab Đăng nhập (true) hoặc Đăng ký (false)
  final bool initialIsLogin;

  const AuthScreen({
    super.key,
    this.initialIsLogin = true,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late bool _isLoginMode;
  late final TabController _tabController;
  final AuthService _authService = AuthService();

  // Controllers cho Đăng nhập
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  bool _loginObscurePassword = true;
  bool _rememberMe = true;
  bool _isLoginLoading = false;

  // Controllers cho Đăng ký
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _registerFormKey = GlobalKey<FormState>();
  bool _registerObscurePassword = true;
  bool _registerObscureConfirmPassword = true;
  bool _agreedToTerms = true;
  bool _isRegisterLoading = false;

  @override
  void initState() {
    super.initState();
    _isLoginMode = widget.initialIsLogin;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIsLogin ? 0 : 1,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _isLoginMode = _tabController.index == 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  /// Xử lý hành động Đăng Nhập
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoginLoading = true);

    final result = await _authService.login(
      emailOrPhone: _loginEmailController.text,
      password: _loginPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoginLoading = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceCard,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.wattageSafe),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
        ),
      );
      Navigator.pop(context, true);
    } else {
      _showErrorDialog(result.message);
    }
  }

  /// Xử lý hành động Đăng Ký
  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      _showErrorDialog('Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của Joppe.');
      return;
    }

    setState(() => _isRegisterLoading = true);

    final result = await _authService.register(
      fullName: _registerNameController.text,
      email: _registerEmailController.text,
      phoneNumber: _registerPhoneController.text,
      password: _registerPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _isRegisterLoading = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceCard,
          content: Row(
            children: [
              const Icon(Icons.stars, color: AppColors.primaryBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
        ),
      );
      Navigator.pop(context, true);
    } else {
      _showErrorDialog(result.message);
    }
  }


  /// Hiển thị Dialog báo lỗi
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(24))),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.accentRed, size: 22),
            SizedBox(width: 8),
            Text(
              'THÔNG BÁO XÁC THỰC',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textOnAction,
              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÃ HIỂU'),
          ),
        ],
      ),
    );
  }

  /// Dialog Khôi phục mật khẩu (Quên mật khẩu)
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _loginEmailController.text);
    final newPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(24))),
        title: const Text(
          'KHÔI PHỤC MẬT KHẨU',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập email tài khoản và mật khẩu mới bạn muốn đổi:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Email đã đăng ký',
                labelStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(14))),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                labelStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(14))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('HỦY', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textOnAction,
              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
            ),
            onPressed: () async {
              final res = await _authService.resetPassword(
                email: emailController.text,
                newPassword: newPasswordController.text,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (!mounted) return;
              if (res.isSuccess) {
                _loginPasswordController.text = newPasswordController.text;
                _loginEmailController.text = emailController.text;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                _showErrorDialog(res.message);
              }
            },
            child: const Text('ĐẶT LẠI MẬT KHẨU', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/joppe_hornet.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'JOPPE',
                    style: TextStyle(
                      color: AppColors.textOnAction,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'JOPPE',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 2.0,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '•',
                style: TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _isLoginMode ? 'ĐĂNG NHẬP HỆ THỐNG' : 'ĐĂNG KÝ TÀI KHOẢN',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Cyber Badge
                  _buildBrandHeader(),
                  const SizedBox(height: 24),

                  // Tab Switcher bo góc công thái học
                  _buildTabSwitcher(),
                  const SizedBox(height: 20),

                  // Form Container bo cong mềm mại
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      border: Border.all(color: AppColors.borderLight, width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06242424),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22),
                    child: _isLoginMode ? _buildLoginForm() : _buildRegisterForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08242424),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/joppe_hornet.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.shield_outlined, color: AppColors.primaryBlue, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'JOPPE GAMING & WORKSTATION',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hệ Thống Xác Thực Người Dùng Chuẩn Bảo Mật',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              onTap: () {
                _tabController.animateTo(0);
                setState(() => _isLoginMode = true);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isLoginMode ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  boxShadow: _isLoginMode
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'ĐĂNG NHẬP',
                  style: TextStyle(
                    color: _isLoginMode ? AppColors.textOnAction : AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              onTap: () {
                _tabController.animateTo(1);
                setState(() => _isLoginMode = false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isLoginMode ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  boxShadow: !_isLoginMode
                      ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'ĐĂNG KÝ',
                  style: TextStyle(
                    color: !_isLoginMode ? AppColors.textOnAction : AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FORM ĐĂNG NHẬP
  // ===========================================================================
  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề form
          const Text(
            'ĐĂNG NHẬP TÀI KHOẢN',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Email / Số điện thoại
          _buildInputLabel('Email hoặc Số điện thoại'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _loginEmailController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _buildInputDecoration(
              hint: 'Nhập email (ví dụ: gamer@joppe.vn) hoặc SĐT',
              icon: Icons.person_outline,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập email hoặc số điện thoại';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Mật khẩu
          _buildInputLabel('Mật khẩu'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _loginPasswordController,
            obscureText: _loginObscurePassword,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _buildInputDecoration(
              hint: 'Nhập mật khẩu',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _loginObscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSubtle,
                  size: 18,
                ),
                onPressed: () {
                  setState(() => _loginObscurePassword = !_loginObscurePassword);
                },
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Dòng tiện ích: Ghi nhớ & Quên mật khẩu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.primaryBlue,
                      checkColor: AppColors.textOnAction,
                      side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(6))),
                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ghi nhớ đăng nhập',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              InkWell(
                onTap: _showForgotPasswordDialog,
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nút Đăng Nhập chính
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textOnAction,
              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            onPressed: _isLoginLoading ? null : _handleLogin,
            child: _isLoginLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnAction),
                  )
                : const Text(
                    'ĐĂNG NHẬP NGAY',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                  ),
          ),
          const SizedBox(height: 24),

          // Đăng nhập bên thứ 3
          _buildSocialLogins(),
        ],
      ),
    );
  }

  // ===========================================================================
  // FORM ĐĂNG KÝ
  // ===========================================================================
  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề form
          const Text(
            'TẠO TÀI KHOẢN MỚI',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Họ và tên
          _buildInputLabel('Họ và tên'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _registerNameController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _buildInputDecoration(
              hint: 'Ví dụ: Trần Văn An',
              icon: Icons.badge_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập họ và tên của bạn';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Email
          _buildInputLabel('Địa chỉ Email'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _registerEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _buildInputDecoration(
              hint: 'Ví dụ: user@gmail.com',
              icon: Icons.email_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                return 'Định dạng email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Số điện thoại
          _buildInputLabel('Số điện thoại liên hệ'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _registerPhoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _buildInputDecoration(
              hint: 'Ví dụ: 0912345678',
              icon: Icons.phone_android_outlined,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Vui lòng nhập số điện thoại';
              }
              if (v.trim().length < 9) {
                return 'Số điện thoại quá ngắn';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Mật khẩu
          _buildInputLabel('Mật khẩu'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: _registerObscurePassword,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _buildInputDecoration(
              hint: 'Tối thiểu 6 ký tự',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _registerObscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSubtle,
                  size: 18,
                ),
                onPressed: () {
                  setState(() => _registerObscurePassword = !_registerObscurePassword);
                },
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 6) {
                return 'Mật khẩu phải chứa ít nhất 6 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Xác nhận mật khẩu
          _buildInputLabel('Xác nhận mật khẩu'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _registerConfirmPasswordController,
            obscureText: _registerObscureConfirmPassword,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: _buildInputDecoration(
              hint: 'Nhập lại mật khẩu vừa đặt',
              icon: Icons.lock_reset,
              suffixIcon: IconButton(
                icon: Icon(
                  _registerObscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSubtle,
                  size: 18,
                ),
                onPressed: () {
                  setState(() => _registerObscureConfirmPassword = !_registerObscureConfirmPassword);
                },
              ),
            ),
            validator: (v) {
              if (v == null || v.trim() != _registerPasswordController.text.trim()) {
                return 'Mật khẩu xác nhận không trùng khớp';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Checkbox đồng ý điều khoản
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _agreedToTerms,
                  activeColor: AppColors.primaryBlue,
                  checkColor: AppColors.textOnAction,
                  side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(6))),
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? true),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tôi đồng ý với Điều khoản dịch vụ và Chính sách bảo mật thông tin khách hàng của Joppe E-Commerce.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nút Đăng Ký
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textOnAction,
              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            onPressed: _isRegisterLoading ? null : _handleRegister,
            child: _isRegisterLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnAction),
                  )
                : const Text(
                    'TẠO TÀI KHOẢN NGAY',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                  ),
          ),
          const SizedBox(height: 16),

          // Chuyển sang Đăng nhập
          Center(
            child: InkWell(
              onTap: () {
                _tabController.animateTo(0);
                setState(() => _isLoginMode = true);
              },
              child: const Text(
                'Đã có tài khoản? Đăng nhập tại đây',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CÁC KHỐI PHỤ TRỢ (SOCIAL LOGINS, INPUT DECORATION)
  // ===========================================================================
  Widget _buildSocialLogins() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(color: AppColors.borderLight, height: 1)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'HOẶC TIẾP TỤC VỚI',
                style: TextStyle(color: AppColors.textSubtle, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: Divider(color: AppColors.borderLight, height: 1)),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.borderLight, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.g_mobiledata, color: AppColors.primaryBlue, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceCard,
                  content: const Text(
                    'Đang kết nối xác thực Google OAuth (/api/v1/auth/google)...',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                ),
              );
            },
            label: const Text(
              'ĐĂNG NHẬP VỚI GOOGLE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
      prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surfaceSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(color: AppColors.borderLight, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(color: AppColors.accentRed, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: const BorderSide(color: AppColors.accentRed, width: 1.6),
      ),
      errorStyle: const TextStyle(color: AppColors.accentRed, fontSize: 11),
    );
  }
}
