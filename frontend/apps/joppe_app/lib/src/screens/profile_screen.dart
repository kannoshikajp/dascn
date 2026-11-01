import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/product.dart';
import '../services/app_api_client.dart';
import '../services/auth_service.dart';
import '../services/store_domain_api_service.dart';
import '../widgets/common/product_image.dart';
import 'auth_screen.dart';

/// Màn hình Hồ Sơ & Quản Lý Tài Khoản Người Dùng Joppe
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
        shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(24))),
        title: const Text(
          'XÁC NHẬN ĐĂNG XUẤT',
          style: TextStyle(color: AppColors.textWhite, fontSize: 14, fontWeight: FontWeight.bold),
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
              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
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
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            Icon(Icons.manage_accounts, color: AppColors.neonCyan, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'TÀI KHOẢN CÁ NHÂN',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textWhite,
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
            icon: const Icon(Icons.home_outlined, color: AppColors.neonCyan),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: user == null ? _buildUnauthenticatedView() : _buildUserProfileView(user),
      ),
    );
  }

  Widget _buildUnauthenticatedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                border: Border.all(color: AppColors.borderLight, width: 2),
              ),
              child: const Icon(Icons.person_off_outlined, color: AppColors.neonCyan, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'CHƯA ĐĂNG NHẬP',
              style: TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
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
                shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
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

  Widget _buildUserProfileView(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card thông tin cá nhân
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.6), width: 1.5),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        border: Border.all(color: AppColors.neonCyan, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: AppColors.neonCyan, size: 36),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Tên & Chi tiết
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
                                    color: AppColors.textWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                color: AppColors.primaryBlue,
                                child: Text(
                                  user.role,
                                  style: const TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SĐT: ${user.phoneNumber}',
                            style: const TextStyle(color: AppColors.textSubtle, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Thống kê điểm thưởng
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('ĐIỂM THƯỞNG', '${user.rewardPoints} PTS', Colors.amberAccent),
                    Container(width: 1, height: 30, color: AppColors.borderLight),
                    _buildStatCol('HẠNG THÀNH VIÊN', user.role, AppColors.neonCyan),
                    Container(width: 1, height: 30, color: AppColors.borderLight),
                    _buildStatCol('ƯU ĐÃI', 'Miễn phí Ship', AppColors.textWhite),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Danh sách hành động quản lý (Đã đấu nối trực tiếp API Backend Joppe)
              _buildActionTile(
                Icons.shopping_bag_outlined,
                'Lịch sử mua hàng',
                'Xem danh sách & tình trạng các đơn hàng linh kiện đã đặt (GET /api/v1/orders/my)',
                onTap: _showOrderHistoryBottomSheet,
              ),
              _buildActionTile(
                Icons.computer,
                'Cấu hình PC đã lưu',
                'Quản lý các dàn PC bạn đã build và lưu lại (GET /api/v1/pc-builder/my)',
                onTap: _showSavedPcBuildsBottomSheet,
              ),
              _buildActionTile(
                Icons.location_on_outlined,
                'Sổ địa chỉ nhận hàng',
                'Quản lý địa chỉ giao hàng tận nơi (GET & POST /api/v1/addresses)',
                onTap: _showAddressBookBottomSheet,
              ),
              _buildActionTile(
                Icons.security,
                'Bảo mật & Đổi mật khẩu',
                'Đổi mật khẩu tài khoản (POST /api/v1/auth/change-password)',
                onTap: _showChangePasswordDialog,
              ),
              _buildActionTile(Icons.headset_mic_outlined, 'Yêu cầu bảo hành & Hỗ trợ kỹ thuật', 'Tra cứu serial và bảo hành linh kiện'),
              const SizedBox(height: 24),

              // Nút Đăng xuất
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentRed,
                  side: const BorderSide(color: AppColors.accentRed, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'ĐĂNG XUẤT KHỎI HỆ THỐNG',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(24))),
            title: const Row(
              children: [
                Icon(Icons.lock_reset, color: AppColors.neonCyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'ĐỔI MẬT KHẨU TÀI KHOẢN',
                  style: TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Kết nối trực tiếp API POST /api/v1/auth/change-password',
                    style: TextStyle(color: AppColors.textSubtle, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: currentPassController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
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
                    controller: newPassController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
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
                    controller: confirmPassController,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('HỦY', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.textOnAction,
                  shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final currentPass = currentPassController.text.trim();
                        final newPass = newPassController.text.trim();
                        final confirmPass = confirmPassController.text.trim();

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

                        setDialogState(() => isSubmitting = true);

                        final result = await _authService.changePassword(
                          currentPassword: currentPass,
                          newPassword: newPass,
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.message),
                              backgroundColor: result.isSuccess ? AppColors.primaryBlue : AppColors.accentRed,
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnAction),
                      )
                    : const Text('LƯU MẬT KHẨU'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCol(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSubtle, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Material(
        color: AppColors.surfaceCard,
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: AppColors.neonCyan, size: 20),
          title: Text(
            title,
            style: const TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSubtle, size: 18),
          onTap: onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tính năng "$title" sẵn sàng hoạt động.'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
        ),
      ),
    );
  }

  /// Chi tiết đơn hàng và timeline trạng thái (GET /api/v1/orders/{id}) theo API_SCHEMA.md mục 11.3
  void _showOrderDetailDialog(String orderId, {Map<String, dynamic>? summaryData}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<ApiResponse>(
          future: StoreDomainApiService().getOrderDetails(orderId),
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final res = snapshot.data;
            final Map<String, dynamic> detail = (res != null && res.isSuccess && res.data is Map)
                ? Map<String, dynamic>.from(res.data as Map)
                : (summaryData ?? <String, dynamic>{});

            final orderCode = detail['orderCode'] ?? detail['orderId'] ?? detail['id'] ?? orderId;
            final status = (detail['orderStatus'] ?? detail['status'] ?? 'PENDING').toString().toUpperCase();
            final paymentStatus = (detail['paymentStatus'] ?? 'UNPAID').toString().toUpperCase();
            final recipientName = detail['recipientName']?.toString() ?? 'Khách hàng JOPPE';
            final recipientPhone = detail['recipientPhone']?.toString() ?? 'Chưa cập nhật';
            final shippingAddress = detail['shippingAddress']?.toString() ?? 'Giao hàng tận nơi';
            final customerNote = detail['customerNote']?.toString();
            final createdAt = detail['createdAt']?.toString() ?? 'Gần đây';
            final shippingFee = (detail['shippingFee'] as num?)?.toDouble() ?? 0.0;
            final grandTotal = (detail['grandTotal'] ?? detail['totalAmount'] as num?)?.toDouble() ?? 0.0;

            final rawItems = detail['items'] ?? detail['orderItems'];
            final items = (rawItems is List)
                ? rawItems.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
                : <Map<String, dynamic>>[];

            Color statusColor = AppColors.neonCyan;
            if (status == 'DELIVERED') statusColor = Colors.greenAccent;
            if (status == 'CANCELLED') statusColor = AppColors.accentRed;
            if (status == 'PENDING') statusColor = Colors.amberAccent;

            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
              contentPadding: const EdgeInsets.all(16),
              titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CHI TIẾT ĐƠN HÀNG',
                          style: TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          orderCode.toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.neonCyan,
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: statusColor.withValues(alpha: 0.2),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
                        )
                      else ...[
                        // Thông tin người nhận
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.location_on_outlined, color: AppColors.neonCyan, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'ĐỊA CHỈ NHẬN HÀNG',
                                    style: TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$recipientName | $recipientPhone',
                                style: const TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                shippingAddress,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                              if (customerNote != null && customerNote.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Ghi chú: $customerNote',
                                  style: const TextStyle(color: AppColors.textSubtle, fontSize: 10.5, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Danh sách linh kiện / sản phẩm
                        const Text(
                          'DANH SÁCH SẢN PHẨM',
                          style: TextStyle(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Đơn hàng tổng hợp từ hệ thống Joppe Cloud.',
                              style: TextStyle(color: AppColors.textSubtle, fontSize: 11),
                            ),
                          )
                        else
                          ...items.map((it) {
                            final pName = it['productName'] ?? it['name'] ?? 'Linh kiện công nghệ';
                            final vName = it['variantName'];
                            final itName = (vName != null && vName.toString().isNotEmpty && vName != 'Default')
                                ? '$pName ($vName)'
                                : pName.toString();
                            final pPrice = (it['unitPrice'] ?? it['price'] as num?)?.toDouble() ?? 0.0;
                            final pQty = (it['quantity'] as num?)?.toInt() ?? 1;
                            final itTotal = (it['totalPrice'] ?? it['itemTotal'] as num?)?.toDouble() ?? (pPrice * pQty);
                            final thumb = AppApiClient.instance.resolveMediaUrl(it['thumbnailUrl'] ?? it['imageUrl']?.toString());

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.searchFieldBg,
                                border: Border.all(color: AppColors.borderLight, width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(border: Border.all(color: AppColors.borderLight)),
                                    child: ProductImage(
                                      imageUrl: thumb,
                                      width: 44,
                                      height: 44,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppColors.textWhite, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${Product.formatVnd(pPrice)} x $pQty',
                                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    Product.formatVnd(itTotal),
                                    style: const TextStyle(color: AppColors.neonCyan, fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 10),
                        // Bảng thanh toán
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: AppColors.primaryDark,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Phí vận chuyển:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  Text(
                                    shippingFee == 0 ? 'MIỄN PHÍ' : Product.formatVnd(shippingFee),
                                    style: const TextStyle(color: AppColors.textWhite, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Thanh toán:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                  Text(
                                    paymentStatus == 'PAID' ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN',
                                    style: TextStyle(
                                      color: paymentStatus == 'PAID' ? Colors.greenAccent : Colors.amberAccent,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: AppColors.borderLight, height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TỔNG CỘNG:', style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 11.5)),
                                  Text(
                                    Product.formatVnd(grandTotal),
                                    style: const TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Thời gian đặt hàng: $createdAt',
                          style: const TextStyle(color: AppColors.textSubtle, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (status == 'PENDING')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      foregroundColor: AppColors.textOnAction,
                      shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text('HỦY ĐƠN HÀNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final cancelRes = await StoreDomainApiService().cancelOrder(detail['id']?.toString() ?? orderCode.toString());
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(cancelRes.isSuccess ? 'Đã hủy đơn hàng thành công.' : 'Không thể hủy đơn lúc này.'),
                            backgroundColor: cancelRes.isSuccess ? AppColors.primaryBlue : AppColors.accentRed,
                          ),
                        );
                        _showOrderHistoryBottomSheet();
                      }
                    },
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ĐÓNG'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 1. Bottom Sheet: Lịch sử mua hàng (GET /api/v1/orders/my & POST /api/v1/orders/{id}/cancel)
  void _showOrderHistoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navyBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<ApiResponse>(
              future: StoreDomainApiService().getMyOrders(),
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final res = snapshot.data;
                final orders = (res != null && res.isSuccess && res.data is List)
                    ? (res.data as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
                    : <Map<String, dynamic>>[];

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      color: AppColors.primaryDark,
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long, color: AppColors.neonCyan, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'LỊCH SỬ ĐƠN HÀNG (JOPPE CLOUD)',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textWhite, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: AppColors.neonCyan),
                            )
                          : orders.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.shopping_bag_outlined, color: AppColors.textSubtle, size: 48),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'CHƯA CÓ ĐƠN HÀNG NÀO',
                                        style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Các đơn hàng bạn đặt sẽ được lưu trữ và cập nhật trạng thái tại đây.',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: orders.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (context, idx) {
                                    final o = orders[idx];
                                    final orderCode = o['orderCode'] ?? o['orderId'] ?? o['id'] ?? 'ORD-#$idx';
                                    final total = (o['grandTotal'] ?? o['totalAmount'] as num?)?.toDouble() ?? 0.0;
                                    final status = (o['orderStatus'] ?? o['status'] ?? 'PENDING').toString().toUpperCase();
                                    final createdAt = o['createdAt']?.toString() ?? 'Gần đây';

                                    Color statusColor = AppColors.neonCyan;
                                    if (status == 'DELIVERED') statusColor = Colors.greenAccent;
                                    if (status == 'CANCELLED') statusColor = AppColors.accentRed;
                                    if (status == 'PENDING') statusColor = Colors.amberAccent;

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceCard,
                                        border: Border.all(color: AppColors.borderLight, width: 1.2),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  orderCode.toString(),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: AppColors.neonCyan,
                                                    fontWeight: FontWeight.w900,
                                                    fontFamily: 'monospace',
                                                    fontSize: 12.5,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                color: statusColor.withValues(alpha: 0.2),
                                                child: Text(
                                                  status,
                                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Ngày tạo: $createdAt',
                                            style: const TextStyle(color: AppColors.textSubtle, fontSize: 10.5),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Expanded(
                                                child: Text(
                                                  'Tổng thanh toán:',
                                                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                Product.formatVnd(total),
                                                style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            alignment: WrapAlignment.end,
                                            spacing: 8,
                                            runSpacing: 6,
                                            children: [
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.neonCyan,
                                                  side: const BorderSide(color: AppColors.borderLight),
                                                  shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                ),
                                                icon: const Icon(Icons.receipt_outlined, size: 14),
                                                label: const Text('CHI TIẾT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                                onPressed: () {
                                                  _showOrderDetailDialog(o['id']?.toString() ?? orderCode.toString(), summaryData: o);
                                                },
                                              ),
                                              if (status == 'PENDING')
                                                TextButton.icon(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: AppColors.accentRed,
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  ),
                                                  icon: const Icon(Icons.cancel_outlined, size: 14),
                                                  label: const Text('HỦY ĐƠN HÀNG', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                                  onPressed: () async {
                                                    final cancelRes = await StoreDomainApiService().cancelOrder(o['id']?.toString() ?? orderCode.toString());
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(cancelRes.isSuccess ? 'Đã hủy đơn hàng thành công.' : 'Không thể hủy đơn lúc này.'),
                                                          backgroundColor: cancelRes.isSuccess ? AppColors.primaryBlue : AppColors.accentRed,
                                                        ),
                                                      );
                                                      Navigator.pop(ctx);
                                                    }
                                                  },
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// 2. Bottom Sheet: Sổ địa chỉ nhận hàng (GET /api/v1/addresses, POST, DELETE)
  void _showAddressBookBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navyBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return FutureBuilder<ApiResponse>(
                  future: StoreDomainApiService().listAddresses(),
                  builder: (context, snapshot) {
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;
                    final res = snapshot.data;
                    final addresses = (res != null && res.isSuccess && res.data is List)
                        ? (res.data as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
                        : <Map<String, dynamic>>[];

                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          color: AppColors.primaryDark,
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.neonCyan, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'SỔ ĐỊA CHỈ NHẬN HÀNG (API)',
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppColors.textWhite, size: 20),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: AppColors.textOnAction,
                                shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                              label: const Text('+ THÊM ĐỊA CHỈ MỚI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                              onPressed: () => _showAddAddressDialog(onSuccess: () => setSheetState(() {})),
                            ),
                          ),
                        ),
                        Expanded(
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
                              : addresses.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'Chưa có địa chỉ nào được lưu.',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      ),
                                    )
                                  : ListView.separated(
                                      controller: scrollController,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      itemCount: addresses.length,
                                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                                      itemBuilder: (context, idx) {
                                        final a = addresses[idx];
                                        final addrId = a['id']?.toString() ?? '';
                                        final isDefault = a['isDefault'] == true;

                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceCard,
                                            border: Border.all(
                                              color: isDefault ? AppColors.neonCyan : AppColors.borderLight,
                                              width: isDefault ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      a['recipientName']?.toString() ?? 'Khách hàng',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 12),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    a['recipientPhone']?.toString() ?? '',
                                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                                  ),
                                                  const Spacer(),
                                                  if (isDefault)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      color: AppColors.primaryBlue,
                                                      child: const Text('MẶC ĐỊNH', style: TextStyle(color: AppColors.textOnAction, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${a['streetAddress'] ?? ''}, ${a['ward'] ?? ''} ${a['district'] ?? ''} ${a['province'] ?? ''}'.replaceAll(RegExp(r'\s+'), ' ').trim(),
                                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  if (!isDefault)
                                                    TextButton(
                                                      onPressed: () async {
                                                        await StoreDomainApiService().setDefaultAddress(addrId);
                                                        setSheetState(() {});
                                                      },
                                                      child: const Text('Đặt mặc định', style: TextStyle(color: AppColors.neonCyan, fontSize: 11)),
                                                    ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      await StoreDomainApiService().deleteAddress(addrId);
                                                      setSheetState(() {});
                                                    },
                                                    child: const Text('Xóa', style: TextStyle(color: AppColors.accentRed, fontSize: 11)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddAddressDialog({required VoidCallback onSuccess}) {
    final nameCtrl = TextEditingController(text: AuthService().currentUser?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: AuthService().currentUser?.phoneNumber ?? '');
    final streetCtrl = TextEditingController();
    final provinceCtrl = TextEditingController(text: 'TP. Hồ Chí Minh');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(24))),
        title: const Text('THÊM ĐỊA CHỈ NHẬN HÀNG', style: TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                decoration: const InputDecoration(labelText: 'Tên người nhận *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                decoration: const InputDecoration(labelText: 'Số điện thoại *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: streetCtrl,
                style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                decoration: const InputDecoration(labelText: 'Địa chỉ đường, số nhà *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: provinceCtrl,
                style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                decoration: const InputDecoration(labelText: 'Tỉnh / Thành phố *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))), isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('HỦY', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textOnAction,
              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || streetCtrl.text.trim().isEmpty) {
                return;
              }
              await StoreDomainApiService().addAddress(
                recipientName: nameCtrl.text.trim(),
                recipientPhone: phoneCtrl.text.trim(),
                streetAddress: streetCtrl.text.trim(),
                province: provinceCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              onSuccess();
            },
            child: const Text('LƯU ĐỊA CHỈ'),
          ),
        ],
      ),
    );
  }

  /// 3. Bottom Sheet: Cấu hình PC đã lưu (GET /api/v1/pc-builder/my)
  void _showSavedPcBuildsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navyBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<ApiResponse>(
              future: StoreDomainApiService().getMyBuilds(),
              builder: (context, snapshot) {
                final isLoading = snapshot.connectionState == ConnectionState.waiting;
                final res = snapshot.data;
                final builds = (res != null && res.isSuccess && res.data is List)
                    ? (res.data as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
                    : <Map<String, dynamic>>[];

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      color: AppColors.primaryDark,
                      child: Row(
                        children: [
                          const Icon(Icons.desktop_windows, color: AppColors.neonCyan, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'CẤU HÌNH PC ĐÃ LƯU (CLOUD)',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textWhite, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
                          : builds.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Chưa có dàn PC nào được lưu.\nHãy tạo và lưu dàn PC tại mục Build PC!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: builds.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (context, idx) {
                                    final b = builds[idx];
                                    final buildId = b['id']?.toString() ?? 'build-$idx';
                                    final name = b['name']?.toString() ?? 'Dàn PC Custom #$idx';
                                    final total = (b['totalPrice'] as num?)?.toDouble() ?? 0.0;
                                    final wattage = (b['estimatedWattage'] as num?)?.toInt() ?? 0;

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceCard,
                                        border: Border.all(color: AppColors.borderLight, width: 1.2),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                                          const SizedBox(height: 4),
                                          Text('Công suất: ${wattage}W', style: const TextStyle(color: AppColors.neonCyan, fontSize: 11)),
                                          const SizedBox(height: 4),
                                          Text('Tổng chi phí: ${Product.formatVnd(total)}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textOnAction,
              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
            ),
                                              icon: const Icon(Icons.add_shopping_cart, size: 14),
                                              label: const Text('+ THÊM VÀO GIỎ HÀNG', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                              onPressed: () async {
                                                await StoreDomainApiService().addBuildToCart(buildId);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Đã thêm toàn bộ linh kiện PC vào giỏ hàng!'), backgroundColor: AppColors.primaryBlue),
                                                  );
                                                  Navigator.pop(ctx);
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
