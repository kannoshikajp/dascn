import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product.dart';
import '../../../services/app_api_client.dart';
import '../../../services/store_domain_api_service.dart';
import '../../../widgets/common/product_image.dart';
import '../atoms/order_status_badge.dart';

/// Compound: Hộp thoại xem chi tiết đơn hàng
class OrderDetailDialog extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic>? summaryData;
  final VoidCallback? onOrderCancelled;

  const OrderDetailDialog({
    super.key,
    required this.orderId,
    this.summaryData,
    this.onOrderCancelled,
  });

  static Future<void> show(
    BuildContext context,
    String orderId, {
    Map<String, dynamic>? summaryData,
    VoidCallback? onOrderCancelled,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => OrderDetailDialog(
        orderId: orderId,
        summaryData: summaryData,
        onOrderCancelled: onOrderCancelled,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      orderCode.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OrderStatusBadge(status: status),
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
                      child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                    )
                  else ...[
                    // Thông tin người nhận
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.searchFieldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: AppColors.primaryBlue, size: 15),
                              SizedBox(width: 4),
                              Text(
                                'ĐỊA CHỈ NHẬN HÀNG',
                                style: TextStyle(color: AppColors.primaryBlue, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$recipientName | $recipientPhone',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
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
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Chi tiết sản phẩm trong đơn hàng.',
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
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight, width: 0.8),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.borderLight),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ProductImage(
                                    imageUrl: thumb,
                                    width: 44,
                                    height: 44,
                                  ),
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
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
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
                                style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 10),
                    // Bảng thanh toán
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.searchFieldBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Phí vận chuyển:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              Text(
                                shippingFee == 0 ? 'MIỄN PHÍ' : Product.formatVnd(shippingFee),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
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
                                  color: paymentStatus == 'PAID' ? Colors.green : Colors.orange,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: AppColors.borderLight, height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TỔNG CỘNG:', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11.5)),
                              Text(
                                Product.formatVnd(grandTotal),
                                style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w900, fontSize: 13.5),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 14),
                label: const Text('HỦY ĐƠN HÀNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final cancelRes = await StoreDomainApiService().cancelOrder(detail['id']?.toString() ?? orderCode.toString());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(cancelRes.isSuccess ? 'Đã hủy đơn hàng thành công.' : 'Không thể hủy đơn lúc này.'),
                        backgroundColor: cancelRes.isSuccess ? AppColors.primaryBlue : AppColors.accentRed,
                      ),
                    );
                    onOrderCancelled?.call();
                  }
                },
              ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('ĐÓNG'),
            ),
          ],
        );
      },
    );
  }
}
