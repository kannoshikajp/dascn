import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/catalog_service.dart';
import '../widgets/common/cyber_effects.dart';
import '../widgets/common/product_image.dart';
import 'checkout_screen.dart';

/// Màn hình giỏ hàng công nghệ Joppe E-Commerce hỗ trợ quản lý số lượng, đồng bộ 2 chiều với API và chuyển sang thanh toán
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Đồng bộ giỏ hàng từ máy chủ backend ngay khi mở màn hình giỏ hàng
    CartService().syncWithServer();
  }

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();

    return ListenableBuilder(
      listenable: cartService,
      builder: (context, _) {
        final isEmpty = cartService.isEmpty;

        return Scaffold(
          backgroundColor: AppColors.navyBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            titleSpacing: 0,
            shape: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
            title: InkWell(
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    color: AppColors.surfaceCard,
                    child: const Text(
                      'JOPPE',
                      style: TextStyle(
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'GIỎ HÀNG ${isEmpty ? '' : '(${cartService.totalItemCount})'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (!isEmpty)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceCard,
                        shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(24))),
                        title: const Text(
                          'XÓA TẤT CẢ GIỎ HÀNG?',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        content: const Text(
                          'Bạn có chắc chắn muốn xóa toàn bộ sản phẩm khỏi giỏ hàng không?',
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
                              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(14))),
                            ),
                            onPressed: () {
                              cartService.clearCart();
                              Navigator.pop(ctx);
                            },
                            child: const Text('XÓA HẾT'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppColors.textMuted),
                  label: const Text('XÓA HẾT', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ),
              IconButton(
                tooltip: 'Trang chủ JOPPE',
                icon: const Icon(Icons.home_outlined, color: AppColors.neonCyan),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.neonCyan,
            backgroundColor: AppColors.primaryDark,
            onRefresh: () async {
              await cartService.syncWithServer();
            },
            child: isEmpty ? _buildEmptyCart(context) : _buildCartContent(context, cartService),
          ),
          bottomNavigationBar: isEmpty ? null : _buildBottomCheckoutBar(context, cartService),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        border: Border.all(color: AppColors.borderLight, width: 2),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'GIỎ HÀNG ĐANG TRỐNG',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chưa có linh kiện hoặc thiết bị nào trong giỏ.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.textOnAction,
                        shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text(
                        'TIẾP TỤC MUA SẮM',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartContent(BuildContext context, CartService cartService) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step progress indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    '1. GIỎ HÀNG',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Icon(Icons.arrow_right_alt, color: AppColors.borderLight, size: 16),
                Expanded(
                  child: Text(
                    '2. THANH TOÁN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSubtle,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Icon(Icons.arrow_right_alt, color: AppColors.borderLight, size: 16),
                Expanded(
                  child: Text(
                    '3. HOÀN TẤT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSubtle,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Thanh tiến trình Miễn phí vận chuyển (Freeship Progress Bar)
          _buildFreeshipProgressBar(cartService),

          // Items list
          ...cartService.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: AppColors.borderLight, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04242424),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Container(
                      width: 72,
                      height: 72,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ProductImage(
                        imageUrl: item.product.imageUrl,
                        componentType: item.product.componentType,
                        brand: item.product.brand,
                        width: 72,
                        height: 72,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Details and quantity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  cartService.removeItem(item.product.id);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.product.brand.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.product.formattedPrice,
                                  style: const TextStyle(
                                    color: AppColors.neonCyan,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Quantity controller
                              Container(
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        cartService.updateQuantity(item.product.id, item.quantity - 1);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: const Icon(Icons.remove, size: 14, color: AppColors.textWhite),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      color: AppColors.surfaceCard,
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          color: AppColors.textWhite,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        cartService.updateQuantity(item.product.id, item.quantity + 1);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: const Icon(Icons.add, size: 14, color: AppColors.textWhite),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Gợi ý phụ kiện công nghệ mua kèm (Cross-sell)
          _buildAccessoryCrossSell(context, cartService),
        ],
      ),
    );
  }

  /// Thanh tiến trình Miễn phí vận chuyển (Freeship Progress Bar)
  Widget _buildFreeshipProgressBar(CartService cartService) {
    const freeshipThreshold = 2000000.0;
    final subtotal = cartService.subtotal;
    final isQualified = subtotal >= freeshipThreshold;
    final remaining = freeshipThreshold - subtotal;
    final ratio = (subtotal / freeshipThreshold).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isQualified
            ? AppColors.surfaceCard
            : AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        border: Border.all(
          color: isQualified ? AppColors.wattageSafe : AppColors.primaryBlue.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isQualified ? Icons.local_shipping : Icons.rocket_launch_outlined,
                color: isQualified ? AppColors.wattageSafe : AppColors.neonCyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isQualified
                      ? '🎉 ĐƠN HÀNG ĐẠT CHUẨN FREESHIP TOÀN QUỐC (TIẾT KIỆM 30.000 ₫)!'
                      : 'Mua thêm ${Product.formatVnd(remaining)} để nhận MIỄN PHÍ VẬN CHUYỂN',
                  style: TextStyle(
                    color: isQualified ? AppColors.wattageSafe : AppColors.textWhite,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          if (!isQualified) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: AppColors.surfaceSubtle,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Dải sản phẩm phụ kiện gợi ý mua kèm (Cross-sell Accessories Carousel)
  Widget _buildAccessoryCrossSell(BuildContext context, CartService cartService) {
    final cartIds = cartService.items.map((i) => i.product.id).toSet();
    final accessories = CatalogService().allProducts
        .where((p) => !cartIds.contains(p.id))
        .take(6)
        .toList();

    if (accessories.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.primaryDark,
            child: const Row(
              children: [
                Icon(Icons.add_shopping_cart, color: AppColors.neonCyan, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'GỢI Ý PHỤ KIỆN MUA KÈM GIÁ TỐT',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: accessories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final product = accessories[index];
                return Container(
                  width: 148,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    border: Border.all(color: AppColors.borderLight, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 72,
                        width: double.infinity,
                        color: AppColors.primaryDark,
                        child: ProductImage(
                          imageUrl: product.imageUrl,
                          componentType: product.componentType,
                          brand: product.brand,
                          fit: BoxFit.cover,
                          height: 72,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          color: AppColors.neonCyan,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TactilePress(
                        onTap: () {
                          cartService.addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã thêm ${product.name} vào giỏ hàng!'),
                              backgroundColor: AppColors.primaryBlue,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          color: AppColors.primaryBlue,
                          alignment: Alignment.center,
                          child: const Text(
                            '+ THÊM NGAY',
                            style: TextStyle(
                              color: AppColors.textOnAction,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckoutBar(BuildContext context, CartService cartService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(top: BorderSide(color: AppColors.borderLight, width: 1.5)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TẠM TÍNH:',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Miễn phí giao hàng từ 2.000.000 ₫',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textSubtle, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      cartService.formattedSubtotal,
                      style: const TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.textOnAction,
                  shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckoutScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.payment, size: 18),
                label: const Text(
                  'TIẾN HÀNH THANH TOÁN',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
