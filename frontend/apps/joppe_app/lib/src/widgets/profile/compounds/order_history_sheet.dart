import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';
import '../../../services/store_domain_api_service.dart';
import '../atoms/order_status_badge.dart';
import 'order_detail_dialog.dart';

/// Compound: Bottom sheet hiển thị lịch sử đơn hàng
class OrderHistorySheet extends StatelessWidget {
  const OrderHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navyBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const OrderHistorySheet(),
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
                      const Icon(Icons.receipt_long, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'LỊCH SỬ ĐƠN HÀNG',
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
                      : orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shopping_bag_outlined, color: AppColors.textSubtle, size: 48),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'CHƯA CÓ ĐƠN HÀNG NÀO',
                                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              orderCode.toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.primaryBlue,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'monospace',
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          OrderStatusBadge(status: status),
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
                                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
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
                                              foregroundColor: AppColors.primaryBlue,
                                              side: const BorderSide(color: AppColors.borderLight),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            ),
                                            icon: const Icon(Icons.receipt_outlined, size: 14),
                                            label: const Text('CHI TIẾT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                            onPressed: () {
                                              OrderDetailDialog.show(
                                                context,
                                                o['id']?.toString() ?? orderCode.toString(),
                                                summaryData: o,
                                                onOrderCancelled: () => Navigator.pop(context),
                                              );
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
                                                  Navigator.pop(context);
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
  }
}
