import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/store_domain_api_service.dart';

/// Compound: Bottom sheet quản lý sổ địa chỉ nhận hàng
class AddressBookSheet extends StatelessWidget {
  const AddressBookSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navyBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const AddressBookSheet(),
    );
  }

  static void showAddAddressDialog(BuildContext context, {required VoidCallback onSuccess}) {
    final nameCtrl = TextEditingController(text: AuthService().currentUser?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: AuthService().currentUser?.phoneNumber ?? '');
    final streetCtrl = TextEditingController();
    final provinceCtrl = TextEditingController(text: 'TP. Hồ Chí Minh');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('THÊM ĐỊA CHỈ NHẬN HÀNG', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
                decoration: const InputDecoration(labelText: 'Tên người nhận *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
                decoration: const InputDecoration(labelText: 'Số điện thoại *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: streetCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
                decoration: const InputDecoration(labelText: 'Địa chỉ đường, số nhà *', border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: provinceCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  @override
  Widget build(BuildContext context) {
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
                          const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'SỔ ĐỊA CHỈ NHẬN HÀNG',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 20),
                            onPressed: () => Navigator.pop(context),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                          label: const Text('+ THÊM ĐỊA CHỈ MỚI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                          onPressed: () => showAddAddressDialog(context, onSuccess: () => setSheetState(() {})),
                        ),
                      ),
                    ),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
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
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceCard,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDefault ? AppColors.primaryBlue : AppColors.borderLight,
                                          width: isDefault ? 1.5 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.02),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
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
                                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.5),
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
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryBlue.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text('MẶC ĐỊNH', style: TextStyle(color: AppColors.primaryBlue, fontSize: 9.5, fontWeight: FontWeight.bold)),
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
                                                  child: const Text('Đặt mặc định', style: TextStyle(color: AppColors.primaryBlue, fontSize: 11)),
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
  }
}
