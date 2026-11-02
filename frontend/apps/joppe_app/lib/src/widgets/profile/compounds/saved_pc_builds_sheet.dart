import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';
import '../../../services/store_domain_api_service.dart';

/// Compound: Bottom sheet hiển thị các cấu hình PC đã lưu
class SavedPcBuildsSheet extends StatelessWidget {
  const SavedPcBuildsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navyBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const SavedPcBuildsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      const Icon(Icons.desktop_windows, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'CẤU HÌNH PC ĐÃ LƯU',
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
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
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
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.borderLight, width: 1),
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
                                      Text(name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 4),
                                      Text('Công suất: ${wattage}W', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text('Tổng chi phí: ${Product.formatVnd(total)}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primaryBlue,
                                            foregroundColor: AppColors.textOnAction,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          icon: const Icon(Icons.add_shopping_cart, size: 14),
                                          label: const Text('+ THÊM VÀO GIỎ HÀNG', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                          onPressed: () async {
                                            await StoreDomainApiService().addBuildToCart(buildId);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Đã thêm toàn bộ linh kiện PC vào giỏ hàng!'), backgroundColor: AppColors.primaryBlue),
                                              );
                                              Navigator.pop(context);
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
  }
}
