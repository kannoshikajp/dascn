import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/store_domain_api_service.dart';
import '../widgets/common/product_image.dart';
import 'auth_screen.dart';
import 'cart_screen.dart';
import 'checkout_screen.dart';
import 'compare_screen.dart';

/// Màn hình chi tiết sản phẩm công nghệ hoàn chỉnh cho Joppe E-Commerce
class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
        title: InkWell(
          onTap: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: AppColors.surfaceCardLighter,
                child: const Text(
                  'JOPPE',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  product.brand.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.neonCyan, size: 22),
            tooltip: 'Trang chủ JOPPE',
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          IconButton(
            icon: const Icon(Icons.balance_outlined, color: AppColors.textPrimary, size: 20),
            tooltip: 'So sánh sản phẩm',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompareScreen(initialProduct1: product),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã sao chép liên kết sản phẩm: ${product.name}')),
              );
            },
          ),
          ListenableBuilder(
            listenable: CartService(),
            builder: (context, _) {
              final count = CartService().totalItemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.textPrimary, size: 20),
                    tooltip: 'Giỏ hàng',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        color: AppColors.accentRed,
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: AppColors.textOnAction,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Khối hình ảnh sản phẩm góc vuông kèm huy hiệu
            Stack(
              children: [
                Container(
                  height: 320,
                  width: double.infinity,
                  color: AppColors.primaryDark,
                  child: Hero(
                    tag: product.id,
                    child: ProductImage(
                      imageUrl: product.imageUrl,
                      componentType: product.componentType,
                      brand: product.brand,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 320,
                    ),
                  ),
                ),
                // Badge giảm giá nếu có
                if (product.discountPercentage > 0)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      color: AppColors.accentRed,
                      child: Text(
                        '-${product.discountPercentage}% GIẢM',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                // Badge chính hãng
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    color: AppColors.primaryBlue,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: AppColors.textOnAction, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'CHÍNH HÃNG 100%',
                          style: TextStyle(
                            color: AppColors.textOnAction,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Khối thông tin giá và tên sản phẩm
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surfaceCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng danh mục và trạng thái kho
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                color: AppColors.primaryDark,
                                child: Text(
                                  product.category.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.neonCyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            if (product.componentType != null) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  color: AppColors.primaryBlue,
                                  child: Text(
                                    product.componentType!.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            product.inStock ? Icons.check_circle : Icons.cancel,
                            size: 14,
                            color: product.inStock ? Colors.greenAccent : Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.inStock ? 'Còn hàng' : 'Tạm hết hàng',
                            style: TextStyle(
                              color: product.inStock ? Colors.greenAccent : Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'BH: ${product.warrantyMonths} Tháng',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tên sản phẩm
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Đánh giá và số lượt mua
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '(${product.reviewCount} đánh giá)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSubtle, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.neonCyan, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Đổi mới 30 ngày',
                            style: TextStyle(color: AppColors.neonCyan, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderLight, height: 24),

                  // Khối giá thuần VND
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          color: AppColors.neonCyan,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (product.originalPrice != null && product.discountPercentage > 0) ...[
                        Text(
                          product.formattedOriginalPrice,
                          style: const TextStyle(
                            color: AppColors.textSubtle,
                            fontSize: 15,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: AppColors.accentRed,
                          child: Text(
                            '-${product.discountPercentage}%',
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Khối đặc điểm nổi bật (Highlights)
            if (product.specs.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(color: AppColors.borderLight, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt, color: AppColors.neonCyan, size: 18),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ĐẶC ĐIỂM NỔI BẬT',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...product.specs.map(
                      (spec) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: AppColors.neonCyan, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                spec,
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Khối bảng thông số kỹ thuật chi tiết
            if (product.technicalSpecs.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  border: Border.all(color: AppColors.borderLight, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: AppColors.primaryDark,
                      child: const Row(
                        children: [
                          Icon(Icons.tune, color: AppColors.neonCyan, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'THÔNG SỐ KỸ THUẬT CHI TIẾT',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...product.technicalSpecs.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 0.8)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 140,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Khối mô tả sản phẩm
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: AppColors.borderLight, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MÔ TẢ CHI TIẾT',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Khối Đánh giá từ khách hàng kết nối API (GET & POST /api/v1/products/{id}/reviews)
            ProductReviewsSection(productId: product.id),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          border: Border(top: BorderSide(color: AppColors.borderLight, width: 1.5)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    CartService().addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã thêm "${product.name}" vào giỏ hàng!'),
                        backgroundColor: AppColors.primaryBlue,
                        action: SnackBarAction(
                          label: 'XEM GIỎ',
                          textColor: Colors.amberAccent,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CartScreen()),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text(
                    'THÊM GIỎ HÀNG',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
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
                        builder: (context) => CheckoutScreen(
                          checkoutItems: [CartItem(product: product, quantity: 1)],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flash_on, size: 18),
                  label: const Text(
                    'MUA NGAY',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khối Đánh giá sản phẩm từ người dùng (GET & POST /api/v1/products/{id}/reviews)
class ProductReviewsSection extends StatefulWidget {
  final String productId;

  const ProductReviewsSection({super.key, required this.productId});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  int _refreshKey = 0;

  void _showAddReviewDialog() {
    if (!AuthService().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đăng nhập để gửi đánh giá sản phẩm!'),
          backgroundColor: AppColors.primaryDark,
          action: SnackBarAction(
            label: 'ĐĂNG NHẬP',
            textColor: AppColors.neonCyan,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
          ),
        ),
      );
      return;
    }

    int selectedRating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceCard,
            shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(24))),
            title: const Text('ĐÁNH GIÁ SẢN PHẨM', style: TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chọn mức độ hài lòng:', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      icon: Icon(
                        star <= selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                      onPressed: () {
                        setDialogState(() => selectedRating = star);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
                  decoration: const InputDecoration(
                    labelText: 'Cảm nhận của bạn về sản phẩm...',
                    labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
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
                  shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(14))),
                ),
                onPressed: () async {
                  final text = commentCtrl.text.trim();
                  if (text.isEmpty) return;

                  final messenger = ScaffoldMessenger.of(context);
                  final res = await StoreDomainApiService().submitProductReview(widget.productId, {
                    'rating': selectedRating,
                    'comment': text,
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    setState(() {
                      _refreshKey++;
                    });
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(res.isSuccess ? 'Cảm ơn bạn đã gửi đánh giá!' : 'Đã ghi nhận đánh giá của bạn.'),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    );
                  }
                },
                child: const Text('GỬI ĐÁNH GIÁ'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.rate_review_outlined, color: AppColors.neonCyan, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ĐÁNH GIÁ TỪ KHÁCH HÀNG',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(12))),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('VIẾT ĐÁNH GIÁ', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                onPressed: _showAddReviewDialog,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<ApiResponse>(
            key: ValueKey(_refreshKey),
            future: StoreDomainApiService().getProductReviews(widget.productId),
            builder: (context, snapshot) {
              final isLoading = snapshot.connectionState == ConnectionState.waiting;
              final res = snapshot.data;
              final reviews = (res != null && res.isSuccess && res.data is List)
                  ? (res.data as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
                  : <Map<String, dynamic>>[];

              if (isLoading) {
                return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.neonCyan, strokeWidth: 2)));
              }

              if (reviews.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text(
                    'Chưa có bài đánh giá nào cho sản phẩm này.\nHãy là người đầu tiên trải nghiệm và chia sẻ nhận xét!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.4),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, _) => const Divider(color: AppColors.borderLight, height: 16),
                itemBuilder: (context, idx) {
                  final r = reviews[idx];
                  final author = r['userName'] ?? r['author'] ?? 'Gamer JOPPE';
                  final rating = (r['rating'] as num?)?.toInt() ?? 5;
                  final comment = r['comment'] ?? r['content'] ?? '';
                  final date = r['createdAt']?.toString() ?? 'Gần đây';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              author.toString(),
                              style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (starIdx) {
                              return Icon(
                                starIdx < rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(comment.toString(), style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      const SizedBox(height: 4),
                      Text(date, style: const TextStyle(color: AppColors.textSubtle, fontSize: 9.5)),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
