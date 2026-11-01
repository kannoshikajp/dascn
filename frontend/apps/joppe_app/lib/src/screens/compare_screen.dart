import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/catalog_service.dart';
import '../widgets/common/product_image.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';

/// Màn hình So sánh Sản phẩm & Linh kiện phần cứng trực quan
/// Cho phép đặt 2 sản phẩm cạnh nhau để so sánh giá, thông số kỹ thuật, đánh giá và ưu điểm
class CompareScreen extends StatefulWidget {
  final Product? initialProduct1;
  final Product? initialProduct2;

  const CompareScreen({
    super.key,
    this.initialProduct1,
    this.initialProduct2,
  });

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  Product? _product1;
  Product? _product2;

  @override
  void initState() {
    super.initState();
    _initDefaultProducts();
  }

  void _initDefaultProducts() {
    final all = CatalogService().allProducts;

    _product1 = widget.initialProduct1;
    _product2 = widget.initialProduct2;

    // Nếu người dùng mở màn hình so sánh tự do mà chưa chọn sản phẩm nào,
    // tự động đề xuất 2 sản phẩm cùng phân loại để so sánh mẫu trực quan
    if (_product1 == null && all.isNotEmpty) {
      // Ưu tiên chọn 2 card màn hình hoặc 2 CPU để so sánh mẫu
      final gpus = CatalogService().filterProducts('gpu');
      final cpus = CatalogService().filterProducts('cpu');

      if (gpus.length >= 2) {
        _product1 = gpus[0];
        _product2 = gpus[1];
      } else if (cpus.length >= 2) {
        _product1 = cpus[0];
        _product2 = cpus[1];
      } else if (all.length >= 2) {
        _product1 = all[0];
        _product2 = all[1];
      } else {
        _product1 = all.first;
      }
    } else if (_product1 != null && _product2 == null) {
      // Nếu có sẵn sản phẩm 1, tìm sản phẩm 2 cùng loại để gợi ý so sánh
      final sameType = all.where((p) {
        if (p.id == _product1!.id) return false;
        if (_product1!.componentType != null && p.componentType == _product1!.componentType) return true;
        if (p.category.isNotEmpty && p.category.toLowerCase() == _product1!.category.toLowerCase()) return true;
        return p.categorySlugs.any((s) => _product1!.categorySlugs.contains(s));
      }).toList();
      if (sameType.isNotEmpty) {
        _product2 = sameType.first;
      }
    }
  }

  void _swapProducts() {
    setState(() {
      final temp = _product1;
      _product1 = _product2;
      _product2 = temp;
    });
  }

  void _openProductPicker(int slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        String selectedCategory = 'Tất cả';

        // Danh mục và phân loại sản phẩm động đồng bộ 100% từ API máy chủ Joppe
        final apiCategories = CatalogService().storeCategories;
        final categories = [
          'Tất cả',
          ...apiCategories.map((c) => c.shortName.isNotEmpty ? c.shortName : c.name).toSet(),
        ];

        return StatefulBuilder(
          builder: (context, setModalState) {
            final allProducts = CatalogService().allProducts;
            final candidateProducts = selectedCategory == 'Tất cả'
                ? allProducts
                : CatalogService().filterProducts(selectedCategory);

            final filtered = candidateProducts.where((p) {
              if (searchQuery.isNotEmpty) {
                final q = searchQuery.toLowerCase();
                return p.name.toLowerCase().contains(q) ||
                    p.brand.toLowerCase().contains(q) ||
                    p.specs.any((s) => s.toLowerCase().contains(q));
              }
              return true;
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Header Modal
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      color: AppColors.primaryBlue,
                      child: Row(
                        children: [
                          const Icon(Icons.balance_outlined, color: AppColors.textOnAction, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'CHỌN SẢN PHẨM SO SÁNH ($slot)',
                              style: const TextStyle(
                                color: AppColors.textOnAction,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textOnAction, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // Filter category pills
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final cat = categories[idx];
                          final isSelected = cat == selectedCategory;
                          return InkWell(
                            borderRadius: BorderRadius.circular(9999),
                            onTap: () {
                              setModalState(() {
                                selectedCategory = cat;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryBlue : AppColors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(
                                  color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? AppColors.textOnAction : AppColors.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Search input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: TextField(
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm sản phẩm theo tên, model...',
                          hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 12.5),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                          filled: true,
                          fillColor: AppColors.searchFieldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val.trim();
                          });
                        },
                      ),
                    ),

                    // Danh sách sản phẩm
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy sản phẩm phù hợp.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final p = filtered[idx];
                                return Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(10),
                                    leading: Container(
                                      width: 55,
                                      height: 55,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ProductImage(
                                        imageUrl: p.imageUrl,
                                        componentType: p.componentType,
                                        brand: p.brand,
                                        width: 55,
                                        height: 55,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    title: Text(
                                      p.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Text(
                                            p.formattedPrice,
                                            style: const TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceSubtle,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              p.brand,
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: AppColors.textOnAction,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (slot == 1) {
                                            _product1 = p;
                                          } else {
                                            _product2 = p;
                                          }
                                        });
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('CHỌN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SO SÁNH SẢN PHẨM',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (_product1 != null && _product2 != null)
            IconButton(
              tooltip: 'Đổi vị trí sản phẩm',
              icon: const Icon(Icons.swap_horiz, color: AppColors.primaryBlue),
              onPressed: _swapProducts,
            ),
          IconButton(
            tooltip: 'Làm mới so sánh',
            icon: const Icon(Icons.refresh, color: AppColors.textMuted),
            onPressed: () {
              setState(() {
                _product1 = null;
                _product2 = null;
                _initDefaultProducts();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ so sánh 2 sản phẩm trên cùng
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProductHeaderCard(1, _product1)),
                const SizedBox(width: 10),
                Expanded(child: _buildProductHeaderCard(2, _product2)),
              ],
            ),

            const SizedBox(height: 14),

            // Banner phân tích chênh lệch giá & ưu đãi
            if (_product1 != null && _product2 != null) _buildPriceDiffBanner(),

            const SizedBox(height: 14),

            // Bảng Ma trận so sánh thông số kỹ thuật (Specs Matrix)
            if (_product1 != null || _product2 != null) _buildSpecsComparisonTable(),

            const SizedBox(height: 14),

            // Điểm nổi bật & Ưu điểm vượt trội của từng sản phẩm
            if (_product1 != null && _product2 != null) _buildHighlightsComparison(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeaderCard(int slot, Product? product) {
    if (product == null) {
      return Container(
        height: 250,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.primaryBlue, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Sản phẩm $slot',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn sản phẩm để so sánh thông số',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSubtle, fontSize: 11),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: AppColors.textOnAction,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => _openProductPicker(slot),
              child: const Text('CHỌN SẢN PHẨM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04242424),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nút Đổi & Xóa
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.brand.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _openProductPicker(slot),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (slot == 1) {
                          _product1 = null;
                        } else {
                          _product2 = null;
                        }
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16, color: AppColors.accentRed),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Ảnh sản phẩm
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
              );
            },
            child: Container(
              height: 110,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: ProductImage(
                  imageUrl: product.imageUrl,
                  componentType: product.componentType,
                  brand: product.brand,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Tên sản phẩm
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
              );
            },
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Giá bán & Giá gốc
          Text(
            product.formattedPrice,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
            ),
          ),
          if (product.originalPrice != null && product.originalPrice! > product.price) ...[
            Text(
              Product.formatVnd(product.originalPrice!),
              style: const TextStyle(
                color: AppColors.textSubtle,
                fontSize: 10,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Nút thêm vào giỏ hàng
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textOnAction,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 8),
              elevation: 0,
            ),
            onPressed: () {
              CartService().addItem(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã thêm ${product.name} vào giỏ hàng!'),
                  backgroundColor: AppColors.primaryBlue,
                  action: SnackBarAction(
                    label: 'XEM GIỎ',
                    textColor: Colors.amberAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_shopping_cart, size: 14),
            label: const Text(
              'MUA NGAY',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDiffBanner() {
    final diff = (_product1!.price - _product2!.price).abs();
    final cheaperProduct = _product1!.price < _product2!.price ? _product1! : _product2!;
    final moreExpensiveProduct = _product1!.price >= _product2!.price ? _product1! : _product2!;

    final percent = moreExpensiveProduct.price > 0
        ? ((diff / moreExpensiveProduct.price) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardLighter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderAccent.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.price_check, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHÊNH LỆCH: ${Product.formatVnd(diff)} ($percent%)',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cheaperProduct.name} tiết kiệm hơn so với ${moreExpensiveProduct.name}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsComparisonTable() {
    final p1 = _product1;
    final p2 = _product2;

    // Tổng hợp tất cả các trường thông số kỹ thuật
    final allKeys = <String>{};
    if (p1 != null) allKeys.addAll(p1.technicalSpecs.keys);
    if (p2 != null) allKeys.addAll(p2.technicalSpecs.keys);

    final standardRows = [
      {'label': 'Thương hiệu', 'v1': p1?.brand ?? '-', 'v2': p2?.brand ?? '-'},
      {'label': 'Phân loại', 'v1': p1?.category ?? '-', 'v2': p2?.category ?? '-'},
      {'label': 'Bảo hành', 'v1': p1 != null ? '${p1.warrantyMonths} tháng' : '-', 'v2': p2 != null ? '${p2.warrantyMonths} tháng' : '-'},
      {'label': 'Tình trạng kho', 'v1': (p1?.inStock ?? false) ? 'Còn hàng' : 'Tạm hết', 'v2': (p2?.inStock ?? false) ? 'Còn hàng' : 'Tạm hết'},
      {'label': 'Đánh giá', 'v1': p1 != null ? '★ ${p1.rating} (${p1.reviewCount})' : '-', 'v2': p2 != null ? '★ ${p2.rating} (${p2.reviewCount})' : '-'},
    ];

    for (final k in allKeys) {
      standardRows.add({
        'label': k,
        'v1': p1?.technicalSpecs[k] ?? '-',
        'v2': p2?.technicalSpecs[k] ?? '-',
      });
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bảng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.surfaceSubtle,
            child: const Row(
              children: [
                Icon(Icons.tune, color: AppColors.primaryBlue, size: 16),
                SizedBox(width: 8),
                Text(
                  'BẢNG SO SÁNH THÔNG SỐ KỸ THUẬT',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Từng hàng thông số
          ...standardRows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final isEven = idx % 2 == 0;
            final isDiff = row['v1'] != row['v2'] && row['v1'] != '-' && row['v2'] != '-';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isEven ? AppColors.surfaceCard : AppColors.navyBackground.withValues(alpha: 0.5),
                border: const Border(bottom: BorderSide(color: AppColors.borderLight, width: 0.8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row['label']!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row['v1']!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDiff ? AppColors.primaryBlue : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 16, color: AppColors.borderLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          row['v2']!,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDiff ? AppColors.primaryBlue : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHighlightsComparison() {
    final p1 = _product1!;
    final p2 = _product2!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_outline, color: AppColors.primaryBlue, size: 16),
              SizedBox(width: 6),
              Text(
                'ĐẶC ĐIỂM NỔI BẬT NỔI TRỘI',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p1.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(height: 6),
                    ...p1.specs.take(4).map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 80, color: AppColors.borderLight),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p2.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(height: 6),
                    ...p2.specs.take(4).map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
