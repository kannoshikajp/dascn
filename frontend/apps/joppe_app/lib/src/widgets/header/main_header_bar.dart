import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';

/// Main Header Bar: Nền xanh đen đậm, logo JOPPE góc cạnh, ô tìm kiếm tích hợp dropdown và giỏ hàng có badge vuông
class MainHeaderBar extends StatefulWidget {
  final VoidCallback? onCartTap;
  final VoidCallback? onAccountTap;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onLogoTap;

  const MainHeaderBar({
    super.key,
    this.onCartTap,
    this.onAccountTap,
    this.onSearch,
    this.onLogoTap,
  });

  @override
  State<MainHeaderBar> createState() => _MainHeaderBarState();
}

class _MainHeaderBarState extends State<MainHeaderBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 800;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hàng 1 trên Mobile: Logo bên trái + User & Cart bên phải
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLogo(),
                    Row(
                      children: [
                        _buildAccountButton(compact: true),
                        const SizedBox(width: 8),
                        _buildCartButton(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Hàng 2 trên Mobile: Thanh tìm kiếm toàn chiều rộng
                _buildSearchBar(),
              ],
            );
          }

          // Giao diện Desktop / Màn hình rộng
          return Row(
            children: [
              _buildLogo(),
              const SizedBox(width: 24),
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 24),
              _buildAccountButton(compact: false),
              const SizedBox(width: 12),
              _buildCartButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        _searchController.clear();
        widget.onLogoTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3), width: 1.5),
          color: AppColors.surfaceCard,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/joppe_hornet.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'JOPPE',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.searchFieldBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          // Input field
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Nhập sản phẩm cần tìm...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: widget.onSearch,
            ),
          ),
          // Pill Search Button
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => widget.onSearch?.call(_searchController.text),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, color: AppColors.textOnAction, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Tìm kiếm',
                    style: TextStyle(
                      color: AppColors.textOnAction,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountButton({required bool compact}) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, _) {
        final user = AuthService().currentUser;
        final isLoggedIn = user != null;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onAccountTap,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLoggedIn ? AppColors.primaryBlue.withValues(alpha: 0.8) : AppColors.borderLight,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLoggedIn ? Icons.verified_user : Icons.person,
                    color: isLoggedIn ? AppColors.primaryBlue : AppColors.primaryBlue,
                    size: 16,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? user.fullName : 'Tài khoản',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isLoggedIn ? user.role : 'Đăng nhập / Đăng ký',
                        style: TextStyle(
                          color: isLoggedIn ? AppColors.primaryBlue : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: isLoggedIn ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartButton() {
    return ListenableBuilder(
      listenable: CartService(),
      builder: (context, _) {
        final count = CartService().totalItemCount;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onCartTap,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart, color: AppColors.textOnAction, size: 18),
                const SizedBox(width: 8),
                // Pill Red Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: AppColors.textOnAction,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
