import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../data/home_mock_data.dart';
import '../models/category_node.dart';
import '../models/component_category.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/catalog_service.dart';
import '../widgets/common/cyber_effects.dart';
import '../widgets/common/product_image.dart';
import '../widgets/header/joppe_header.dart';
import 'ai_advisor_screen.dart';
import 'auth_screen.dart';
import 'budget_estimator_screen.dart';
import 'build_pc_screen.dart';
import 'cart_screen.dart';
import 'compare_screen.dart';
import 'product_details_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  String _activeFilter = 'Tất cả';
  String _selectedBrand = 'Tất cả';
  String _searchQuery = '';
  String _sortBy = 'default';
  String _priceFilter = 'all';
  bool _showScrollToTop = false;
  int _currentBottomNavIndex = 0;
  Timer? _flashSaleTimer;
  Duration _flashSaleRemaining = const Duration(hours: 3, minutes: 42, seconds: 15);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    CatalogService().addListener(_onCatalogChanged);
    _flashSaleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_flashSaleRemaining.inSeconds > 0) {
          _flashSaleRemaining = _flashSaleRemaining - const Duration(seconds: 1);
        } else {
          _flashSaleRemaining = const Duration(hours: 4, minutes: 0, seconds: 0);
        }
      });
    });
  }

  void _onCatalogChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    final show = _scrollController.hasClients && _scrollController.offset > 350;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  @override
  void dispose() {
    CatalogService().removeListener(_onCatalogChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _flashSaleTimer?.cancel();
    super.dispose();
  }

  void _resetToHome() {
    setState(() {
      _activeFilter = 'Tất cả';
      _selectedBrand = 'Tất cả';
      _searchQuery = '';
      _sortBy = 'default';
      _priceFilter = 'all';
    });
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String get _activeFilterDisplayName {
    if (_activeFilter == 'Tất cả') return 'Tất cả';
    final clean = _activeFilter.toLowerCase().replaceAll(RegExp(r'^/+'), '').trim();
    if (clean == 'khuyến mãi' || clean == 'promo' || clean == 'khuyen-mai' || clean == 'sale') {
      return 'Khuyến Mãi & Giảm Giá';
    }
    if (clean == 'pc-part') {
      return 'Linh Kiện Build PC';
    }

    final catalog = CatalogService();

    // 1. Tra cứu trong cây danh mục CategoryNode
    final filterId = int.tryParse(clean);
    String? foundName;
    void searchTree(List<CategoryNode> nodes) {
      for (final n in nodes) {
        final nSlug = n.slug.toLowerCase().replaceAll(RegExp(r'^/+'), '').trim();
        final nName = n.categoryName.toLowerCase().trim();
        if ((filterId != null && n.id == filterId) || nSlug == clean || nName == clean) {
          foundName = n.displayName;
          return;
        }
        if (n.children.isNotEmpty) {
          searchTree(n.children);
          if (foundName != null) return;
        }
      }
    }

    searchTree(catalog.categoryTree);
    if (foundName != null) return foundName!;

    // 2. Tra cứu trong danh sách storeCategories
    for (final sc in catalog.storeCategories) {
      final scSlug = (sc.slug ?? sc.id).toLowerCase().replaceAll(RegExp(r'^/+'), '').trim();
      if (sc.id.toLowerCase() == clean ||
          sc.name.toLowerCase() == clean ||
          sc.shortName.toLowerCase() == clean ||
          scSlug == clean) {
        return sc.name;
      }
    }

    // 3. Fallback định dạng chữ cái đầu viết hoa
    return _activeFilter
        .replaceAll('-', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  List<Product> get _displayedProducts {
    final catalog = CatalogService();
    List<Product> list = catalog.allProducts;

    // 1. Lọc theo tìm kiếm từ khóa
    if (_searchQuery.isNotEmpty) {
      list = catalog.searchProducts(_searchQuery);
    }

    // 2. Lọc theo danh mục hoặc loại linh kiện
    if (_activeFilter != 'Tất cả') {
      final filteredByCat = catalog.filterProducts(_activeFilter);
      if (_searchQuery.isNotEmpty) {
        final filteredIds = filteredByCat.map((p) => p.id).toSet();
        list = list.where((p) => filteredIds.contains(p.id)).toList();
      } else {
        list = filteredByCat;
      }
    }

    // 3. Lọc theo khoảng giá
    if (_priceFilter == 'under_10m') {
      list = list.where((p) => p.price < 10000000).toList();
    } else if (_priceFilter == '10m_25m') {
      list = list.where((p) => p.price >= 10000000 && p.price <= 25000000).toList();
    } else if (_priceFilter == '25m_50m') {
      list = list.where((p) => p.price > 25000000 && p.price <= 50000000).toList();
    } else if (_priceFilter == 'above_50m') {
      list = list.where((p) => p.price > 50000000).toList();
    }

    // 4. Lọc theo thương hiệu (Brand Chips)
    if (_selectedBrand != 'Tất cả') {
      final brandLower = _selectedBrand.toLowerCase();
      list = list.where((p) {
        final pBrand = p.brand.toLowerCase();
        final pName = p.name.toLowerCase();
        return pBrand == brandLower || pBrand.contains(brandLower) || pName.contains(brandLower);
      }).toList();
    }

    // 5. Sắp xếp danh sách
    if (_sortBy == 'price_asc') {
      list = List<Product>.from(list)..sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price_desc') {
      list = List<Product>.from(list)..sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'rating') {
      list = List<Product>.from(list)..sort((a, b) => b.rating.compareTo(a.rating));
    }

    return list;
  }

  void _selectFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _searchQuery = '';
    });
    final filterId = int.tryParse(filter);
    if (filterId != null) {
      CatalogService().queryApiProducts(categoryId: filterId);
    } else if (filter != 'Tất cả') {
      final clean = filter.toLowerCase().replaceAll(RegExp(r'^/+'), '').trim();
      int? foundId;
      void findId(List<CategoryNode> nodes) {
        for (final n in nodes) {
          final nSlug = n.slug.toLowerCase().replaceAll(RegExp(r'^/+'), '').trim();
          final nName = n.categoryName.toLowerCase().trim();
          if (nSlug == clean || nName == clean) {
            foundId = n.id;
            return;
          }
          if (n.children.isNotEmpty) findId(n.children);
        }
      }
      findId(CatalogService().categoryTree);
      if (foundId != null) {
        CatalogService().queryApiProducts(categoryId: foundId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = _displayedProducts;
    final isDefaultHome = _activeFilter == 'Tất cả' && _searchQuery.isEmpty;
    final isWide = MediaQuery.of(context).size.width >= 1050;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.navyBackground,
      // Drawer menu danh mục bo góc công thái học (dành cho mobile)
      drawer: isWide ? null : _buildSquareDrawer(),
      floatingActionButton: _buildFloatingActionGroup(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: isWide ? null : _buildBottomNavigationBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Khối Header JOPPE hoàn chỉnh (Top Bar + Main Header + Tabs Bar)
            JoppeHeader(
              onLogoTap: _resetToHome,
              onCartTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
              onAccountTap: () {
                final authService = AuthService();
                if (authService.isAuthenticated) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen(initialIsLogin: true)),
                  );
                }
              },
              onCategoryMenuTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              onSearch: (query) {
                final clean = query.trim();
                setState(() {
                  _searchQuery = clean;
                });
                if (clean.isNotEmpty) {
                  CatalogService().queryApiProducts(search: clean);
                }
              },
              onTabSelected: (tab) {
                if (tab == 'Trợ Lý AI') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AiAdvisorScreen()),
                  );
                } else if (tab == 'Build PC') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BuildPcScreen()),
                  );
                } else if (tab == 'So Sánh') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CompareScreen()),
                  );
                } else if (tab == 'Dự Tính') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BudgetEstimatorScreen()),
                  );
                } else {
                  _selectFilter(tab);
                }
              },
            ),

            // Dải nút danh mục linh kiện phần cứng (Component Category Chips Bar)
            _buildComponentCategorySelector(),

            // Thanh hiển thị trạng thái bộ lọc khi người dùng lọc hoặc tìm kiếm
            if (!isDefaultHome)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.surfaceCard,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.tune, color: AppColors.primaryBlue, size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tìm: "$_searchQuery"'
                                  : 'Mục: $_activeFilter',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${products.length})',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _resetToHome,
                      child: const Row(
                        children: [
                          Icon(Icons.close, color: AppColors.primaryBlue, size: 14),
                          SizedBox(width: 2),
                          Text(
                            'Xem tất cả',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Phần thân trang: Hỗ trợ cuộn mượt mà 100% trong mọi chế độ và hiển thị 3 cột khi trên desktop/wide screen
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cột trái (Desktop only): Menu danh mục cố định
                  if (isWide) _buildDesktopCategorySidebar(),

                  // Cột giữa: Toàn bộ nội dung trang cuộn mượt mà
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isDefaultHome) ...[
                            // 1. Hero Promo Banner từ sản phẩm trực tiếp từ API
                            _buildHeroBanner(products),

                            // 2. Khối Trợ lý AI Tư vấn Build PC Gemini
                            _buildAiAdvisorHomeHub(),

                            // 3. Hàng 5 Banner sự kiện nhỏ (Mini Promo Banners)
                            _buildMiniPromosRow(),

                            // 3. Khối Flash Sale Giờ Vàng đếm ngược thời gian thực
                            _buildFlashSaleBanner(),

                            // 4. 8 Nút tiện ích nhanh (Quick Actions)
                            _buildQuickActionsSection(),

                            // 5. Khối danh mục nổi bật lớn (Category Showcases)
                            _buildCategoryShowcasesSection(),

                            // 6. Tiêu đề danh mục sản phẩm tổng hợp
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                                    ),
                                    child: const Icon(Icons.flash_on, color: AppColors.primaryBlue, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'KHO LINH KIỆN & THIẾT BỊ MỚI NHẤT',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
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

                            // 7. Thanh lọc khoảng giá & Sắp xếp sản phẩm
                            _buildSortAndFilterBar(products.length),

                            // 8. Lưới sản phẩm
                            _buildProductGrid(products),
                          ] else if (products.isEmpty) ...[
                            _buildSortAndFilterBar(products.length),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceSubtle,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.borderLight),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 44,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Không tìm thấy sản phẩm cho "$_searchQuery"'
                                          : 'Chưa có sản phẩm nào trong danh mục "$_activeFilterDisplayName"',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'Vui lòng thử tìm kiếm với từ khóa khác hoặc kiểm tra chính tả.'
                                          : 'Sản phẩm thuộc danh mục này đang được cập nhật từ kho hàng.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: AppColors.textOnAction,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: _resetToHome,
                                      icon: const Icon(Icons.refresh, size: 18),
                                      label: const Text(
                                        'Xem tất cả sản phẩm',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            _buildSortAndFilterBar(products.length),
                            _buildProductGrid(products),
                          ],
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Cột phải (Desktop only): Thanh công cụ tiện ích cố định góc vuông
                  if (isWide) _buildDesktopUtilityToolbar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dải nút phân loại danh mục sản phẩm từ API dạng viên thuốc (Pill Category Bar)
  Widget _buildComponentCategorySelector() {
    final categories = [
      const ComponentCategory(
        id: 'all',
        name: 'Tất cả sản phẩm',
        shortName: 'Tất cả',
        description: 'Tất cả sản phẩm',
        icon: Icons.apps,
      ),
      ...CatalogService().storeCategories,
    ];

    return Container(
      height: 48,
      color: AppColors.navyBackground,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = (cat.id == 'all' && _activeFilter == 'Tất cả') ||
              _activeFilter.toLowerCase() == cat.id.toLowerCase() ||
              _activeFilter.toLowerCase() == cat.name.toLowerCase() ||
              _activeFilter.toLowerCase() == cat.shortName.toLowerCase() ||
              (cat.slug != null && _activeFilter.toLowerCase() == cat.slug!.toLowerCase());

          return InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: () {
              if (cat.id == 'all') {
                _selectFilter('Tất cả');
              } else {
                _selectFilter(cat.slug ?? cat.id);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x05242424),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 15,
                    color: isSelected ? AppColors.textOnAction : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.shortName,
                    style: TextStyle(
                      color: isSelected ? AppColors.textOnAction : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Banner quảng cáo chính Hero Promo Banner lấy trực tiếp từ sản phẩm API
  Widget _buildHeroBanner(List<Product> products) {
    if (products.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08242424),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.sync, color: AppColors.primaryBlue, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đang đồng bộ dữ liệu sản phẩm từ máy chủ API...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    final product = products.first;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A242424),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  height: 190,
                  color: AppColors.searchFieldBg,
                  child: ProductImage(
                    imageUrl: product.imageUrl,
                    componentType: product.componentType,
                    brand: product.brand,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 190,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    product.brand.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textOnAction,
                      fontWeight: FontWeight.w900,
                      fontSize: 10.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_outward,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  Product.formatVnd(product.price),
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 10),
                ...product.specs.take(2).map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: AppColors.warmTan,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s,
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.textOnAction,
                    shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(18))),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 44),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                  child: const Text(
                    'XEM CHI TIẾT SẢN PHẨM',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Khối 8 nút tiện ích nhanh Quick Actions
  Widget _buildQuickActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06242424),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 1.05,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: HomeMockData.quickActions.length,
        itemBuilder: (context, index) {
          final action = HomeMockData.quickActions[index];
          return InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            onTap: () {
              if (action.id == 'qa-build-pc') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BuildPcScreen()),
                );
              } else if (action.id == 'qa-promotions') {
                _selectFilter('Khuyến Mãi');
              } else if (action.id == 'qa-ai-support') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BudgetEstimatorScreen()),
                );
              } else if (action.id == 'qa-chat' || action.id == 'qa-hotline' || action.id == 'qa-zalo') {
                _showContactSupportDialog(action.title);
              } else if (action.id == 'qa-compare') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompareScreen()),
                );
              } else if (action.id == 'qa-calculator') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BudgetEstimatorScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tính năng: ${action.title}'),
                    backgroundColor: AppColors.primaryBlue,
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.navyBackground,
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.6), width: 1),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(action.icon, color: AppColors.primaryBlue, size: 22),
                        const SizedBox(height: 6),
                        Text(
                          action.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (action.badgeText != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          action.badgeText!,
                          style: const TextStyle(
                            color: AppColors.textOnAction,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Khối danh mục lớn Category Showcase Boxes lấy từ danh mục API
  Widget _buildCategoryShowcasesSection() {
    final catalog = CatalogService();
    final categories = catalog.categoryTree;
    if (categories.isEmpty) return const SizedBox.shrink();

    // Thu thập danh mục cấp gốc và cấp con khả dụng
    final candidateCategories = <CategoryNode>[];
    for (final root in categories) {
      candidateCategories.add(root);
      if (root.children.isNotEmpty) {
        candidateCategories.addAll(root.children);
      }
    }

    // Chỉ hiển thị các danh mục thực sự có sản phẩm khả dụng trên cửa hàng
    final activeCategories = candidateCategories.where((c) {
      if (c.productCount > 0) return true;
      return catalog.filterProducts(c.slug).isNotEmpty;
    }).toList();

    if (activeCategories.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'DANH MỤC TRỌNG TÂM',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeCategories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = activeCategories[index];
                final subtitle = item.children.isNotEmpty
                    ? item.children.map((c) => c.categoryName).join(', ')
                    : 'Sản phẩm ${item.categoryName} chính hãng';
                final actualCount = catalog.filterProducts(item.slug).length;
                final countText = actualCount > 0
                    ? '$actualCount Sản phẩm khả dụng'
                    : (item.productCount > 0 ? '${item.productCount} Sản phẩm khả dụng' : 'Khám phá ngay');

                return InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  onTap: () {
                    _selectFilter(item.slug);
                  },
                  child: Container(
                    width: 210,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      border: Border.all(color: AppColors.borderLight, width: 1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06242424),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.categoryName.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            countText,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Lưới sản phẩm vuông bo góc tròn công thái học
  Widget _buildProductGrid(List<Product> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return TactilePress(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsScreen(product: product),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderLight, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06242424),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ảnh sản phẩm & Badge
                Expanded(
                  flex: 6,
                  child: Stack(
                    children: [
                      Container(
                        color: AppColors.searchFieldBg,
                        width: double.infinity,
                        height: double.infinity,
                        child: ProductImage(
                          imageUrl: product.imageUrl,
                          componentType: product.componentType,
                          brand: product.brand,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      // Badge giảm giá dạng pill
                      if (product.discountPercentage > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accentRed,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              '-${product.discountPercentage}%',
                              style: const TextStyle(
                                color: AppColors.textOnAction,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      // Badge thương hiệu dạng pill
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: const [
                              BoxShadow(color: Color(0x10000000), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            product.brand.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Chi tiết tên & giá
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.formattedPrice,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (product.originalPrice != null && product.discountPercentage > 0)
                                    Text(
                                      product.formattedOriginalPrice,
                                      style: const TextStyle(
                                        color: AppColors.textSubtle,
                                        fontSize: 10,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(9999),
                              onTap: () {
                                CartService().addItem(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã thêm "${product.name}" vào giỏ hàng!'),
                                    backgroundColor: AppColors.primaryBlue,
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'XEM GIỎ',
                                      textColor: AppColors.textOnAction,
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
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart,
                                  color: AppColors.textOnAction,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  /// Drawer menu phân loại danh mục bo góc công thái học
  Widget _buildSquareDrawer() {
    return Drawer(
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.category_outlined, color: AppColors.textOnAction, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'DANH MỤC SẢN PHẨM',
                      style: TextStyle(
                        color: AppColors.textOnAction,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Menu Items List với mũi tên nhọn '>'
            Expanded(
              child: ListView(
                children: [
                  // Mục đặc biệt: Xây dựng cấu hình PC
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.build_circle_outlined, color: AppColors.primaryBlue, size: 18),
                    title: const Text(
                      'Xây dựng cấu hình PC',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.primaryBlue, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BuildPcScreen()),
                      );
                    },
                  ),

                  // Mục: Tài khoản cá nhân / Đăng nhập
                  ListenableBuilder(
                    listenable: AuthService(),
                    builder: (context, _) {
                      final isLoggedIn = AuthService().isAuthenticated;
                      final user = AuthService().currentUser;

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isLoggedIn ? Icons.verified_user : Icons.person_outline,
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                        title: Text(
                          isLoggedIn ? 'Tài khoản (${user!.fullName})' : 'Đăng nhập / Đăng ký',
                          style: TextStyle(
                            color: isLoggedIn ? AppColors.primaryBlue : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.borderLight, size: 18),
                        onTap: () {
                          Navigator.pop(context);
                          if (isLoggedIn) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfileScreen()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AuthScreen()),
                            );
                          }
                        },
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.borderLight),

                  // Mục: Tất cả sản phẩm
                  ListTile(
                    dense: true,
                    title: const Text(
                      'Tất cả sản phẩm',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.primaryBlue, size: 18),
                    onTap: () {
                      Navigator.pop(context);
                      _selectFilter('Tất cả');
                    },
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.borderLight),

                  // Dải danh mục động theo cây phân cấp API (GET /api/v1/categories/tree)
                  ListenableBuilder(
                    listenable: CatalogService(),
                    builder: (context, _) {
                      final categoryTree = CatalogService().categoryTree;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final rootNode in categoryTree) ...[
                            if (rootNode.children.isNotEmpty) ...[
                              // Header nhóm từ API
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                color: AppColors.surfaceSubtle,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        rootNode.displayName.toUpperCase(),
                                        style: const TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceCard,
                                        borderRadius: BorderRadius.circular(9999),
                                        border: Border.all(color: AppColors.borderLight, width: 1),
                                      ),
                                      child: Text(
                                        rootNode.formattedSlug,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 9.5,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              for (final child in rootNode.children)
                                _buildCategoryTile(child),

                              const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
                            ] else ...[
                              // Mục danh mục cấp 1 độc lập (ví dụ: Asus /asus)
                              _buildCategoryTile(rootNode),
                              const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
                            ],
                          ],
                        ],
                      );
                    },
                  ),

                  // Header nhóm tiện ích & chức năng nhanh
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppColors.surfaceSubtle,
                    child: const Text(
                      'TIỆN ÍCH & CÔNG CỤ',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.build_outlined, color: AppColors.textMuted, size: 16),
                    title: const Text('Xây Dựng Cấu Hình PC', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
                    subtitle: const Text('Công cụ tự phối linh kiện tương thích', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.borderLight, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BuildPcScreen()));
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.balance_outlined, color: AppColors.textMuted, size: 16),
                    title: const Text('So Sánh Sản Phẩm', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
                    subtitle: const Text('Đối chiếu thông số kỹ thuật 2 sản phẩm', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.borderLight, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen()));
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.calculate_outlined, color: AppColors.textMuted, size: 16),
                    title: const Text('Dự Tính Ngân Sách & Trả Góp', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
                    subtitle: const Text('Tỷ lệ vàng, trả góp 0% & tiền điện EVN', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.borderLight, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetEstimatorScreen()));
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.percent, color: AppColors.accentRed, size: 16),
                    title: const Text('Khuyến Mãi & Giảm Giá', style: TextStyle(color: AppColors.accentRed, fontSize: 12.5, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Các sản phẩm đang có giá ưu đãi sốc', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.borderLight, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      _selectFilter('Khuyến Mãi');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(CategoryNode node) {
    return ListTile(
      dense: true,
      leading: Icon(node.icon, color: AppColors.textMuted, size: 16),
      title: Text(
        node.displayName,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
      ),
      subtitle: Text(
        node.formattedSlug,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (node.productCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: Text(
                '${node.productCount} SP',
                style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const Icon(Icons.chevron_right, color: AppColors.borderLight, size: 16),
        ],
      ),
      onTap: () {
        Navigator.pop(context);
        _selectFilter(node.slug);
      },
    );
  }

  /// Hàng 5 banner sự kiện khuyến mãi nhỏ với góc bo cong công thái học
  Widget _buildMiniPromosRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: HomeMockData.miniPromos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final promo = HomeMockData.miniPromos[index];
          final isSale = promo.themeType == 'sale';

          return InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            onTap: () {
              if (promo.badge == 'HOT DEAL' || promo.badge == '24H') {
                _selectFilter('Khuyến Mãi');
              } else {
                _selectFilter('pc-part');
              }
            },
            child: Container(
              width: 155,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                border: Border.all(
                  color: isSale ? AppColors.accentRed.withValues(alpha: 0.5) : AppColors.borderLight,
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06242424),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          promo.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (promo.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSale ? AppColors.accentRed : AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            promo.badge!,
                            style: const TextStyle(
                              color: AppColors.textOnAction,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    promo.subtitle,
                    style: TextStyle(
                      color: isSale ? AppColors.accentRed : AppColors.primaryBlue,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Xem ngay',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 9.5),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.primaryBlue, size: 13),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Khối Trợ lý AI Tư vấn Build PC & Phần cứng đặt ngay trên màn hình chính (Tạm ẩn)
  Widget _buildAiAdvisorHomeHub() {
    return const SizedBox.shrink();
  }

  /// Banner Flash Sale đếm ngược thời gian thực bo cong hiện đại
  Widget _buildFlashSaleBanner() {
    final hours = _flashSaleRemaining.inHours.toString().padLeft(2, '0');
    final minutes = (_flashSaleRemaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_flashSaleRemaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.25), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06242424),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hàng 1: Tiêu đề Flash Sale & Đồng hồ đếm ngược
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed,
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: const Icon(Icons.bolt, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '⚡ FLASH SALE GIỜ VÀNG',
                          style: TextStyle(
                            color: AppColors.accentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTimeBox(hours),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: Text(':', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        ),
                        _buildTimeBox(minutes),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: Text(':', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                        ),
                        _buildTimeBox(seconds),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Hàng 2: Badge Giá Sốc và Mô tả sản phẩm
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Text(
                        'GIÁ SỐC ĐỘC QUYỀN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Giảm đến 30% cho Laptop ROG Strix, RTX 5080 & Linh kiện AI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Desktop / Wide layout
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '⚡ FLASH SALE GIỜ VÀNG',
                          style: TextStyle(
                            color: AppColors.accentRed,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text(
                            'GIÁ SỐC ĐỘC QUYỀN',
                            style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Giảm đến 30% cho Laptop ROG Strix, RTX 5080 & Linh kiện AI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimeBox(hours),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Text(':', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                  _buildTimeBox(minutes),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Text(':', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                  _buildTimeBox(seconds),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeBox(String digits) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(
        digits,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  /// Thanh sắp xếp và lọc khoảng giá linh hoạt
  Widget _buildSortAndFilterBar(int totalCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06242424),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '$totalCount SẢN PHẨM',
                  style: const TextStyle(
                    color: AppColors.textOnAction,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort, color: AppColors.primaryBlue, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'SẮP XẾP:',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isDense: true,
                          value: _sortBy,
                          dropdownColor: AppColors.surfaceCard,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue, size: 20),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 'default', child: Text('Mặc định')),
                            DropdownMenuItem(value: 'price_asc', child: Text('Giá: Thấp → Cao')),
                            DropdownMenuItem(value: 'price_desc', child: Text('Giá: Cao → Thấp')),
                            DropdownMenuItem(value: 'rating', child: Text('Đánh giá cao')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _sortBy = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 14, thickness: 1, color: AppColors.borderLight),
          // Hàng lọc Thương hiệu (Brand Chips)
          Row(
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined, color: AppColors.primaryBlue, size: 14),
                  SizedBox(width: 4),
                  Text('Hãng:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildBrandChip('Tất cả'),
                      _buildBrandChip('ASUS'),
                      _buildBrandChip('MSI'),
                      _buildBrandChip('Gigabyte'),
                      _buildBrandChip('Intel'),
                      _buildBrandChip('AMD'),
                      _buildBrandChip('Corsair'),
                      _buildBrandChip('Kingston'),
                      _buildBrandChip('Samsung'),
                      _buildBrandChip('Logitech'),
                      _buildBrandChip('Razer'),
                      _buildBrandChip('DeepCool'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, color: AppColors.primaryBlue, size: 14),
                  SizedBox(width: 4),
                  Text('Mức giá:', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              _buildPriceChip('all', 'Tất cả giá'),
              _buildPriceChip('under_10m', '< 10 Triệu'),
              _buildPriceChip('10m_25m', '10 - 25 Triệu'),
              _buildPriceChip('25m_50m', '25 - 50 Triệu'),
              _buildPriceChip('above_50m', '> 50 Triệu'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandChip(String brand) {
    final isSelected = _selectedBrand.toLowerCase() == brand.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TactilePress(
        onTap: () {
          setState(() {
            _selectedBrand = brand;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            brand,
            style: TextStyle(
              color: isSelected ? AppColors.textOnAction : AppColors.textPrimary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceChip(String value, String label) {
    final isSelected = _priceFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TactilePress(
        onTap: () => setState(() => _priceFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textOnAction : AppColors.textPrimary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Cụm nút hành động nổi góc dưới bên phải (Nút Trợ lý AI & Cuộn lên đầu trang)
  Widget _buildFloatingActionGroup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_showScrollToTop) ...[
          InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                );
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10242424),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_up, color: AppColors.primaryBlue, size: 20),
                  Text(
                    'TOP',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        FloatingActionButton.extended(
          heroTag: 'home_ai_advisor_fab',
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiAdvisorScreen()),
            );
          },
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text(
            'Hỏi AI',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }

  /// Thanh điều hướng dưới chân màn hình chuẩn Mobile iOS & Android (Warm Docked Navigation)
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A242424),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: 'Khám phá',
                onTap: _resetToHome,
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.computer_outlined,
                activeIcon: Icons.computer,
                label: 'Cấu hình PC',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BuildPcScreen()),
                  );
                },
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome,
                label: 'Trợ lý AI',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiAdvisorScreen()),
                  );
                },
              ),
              _buildBottomNavItem(
                index: 3,
                icon: Icons.calculate_outlined,
                activeIcon: Icons.calculate,
                label: 'Dự Tính',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgetEstimatorScreen()),
                  );
                },
              ),
              _buildBottomNavItem(
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Tài khoản',
                onTap: () {
                  final auth = AuthService();
                  if (auth.isAuthenticated) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen(initialIsLogin: true)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentBottomNavIndex == index;
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      onTap: () {
        setState(() => _currentBottomNavIndex = index);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.primaryBlue : AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryBlue : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sidebar menu danh mục cố định trên Desktop (Desktop Split View)
  Widget _buildDesktopCategorySidebar() {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(right: BorderSide(color: AppColors.borderLight, width: 1.5)),
      ),
      child: Material(
        color: AppColors.primaryDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              color: AppColors.primaryBlue,
              child: const Row(
                children: [
                  Icon(Icons.category_outlined, color: AppColors.textOnAction, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DANH MỤC PHẦN CỨNG',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textOnAction,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListenableBuilder(
              listenable: CatalogService(),
              builder: (context, _) {
                final categoryTree = CatalogService().categoryTree;
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.build_circle_outlined, color: AppColors.neonCyan, size: 16),
                      title: const Text('Xây dựng cấu hình PC', style: TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.neonCyan, size: 14),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BuildPcScreen()));
                      },
                    ),
                    const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
                    ListTile(
                      dense: true,
                      title: const Text('Tất cả sản phẩm', style: TextStyle(color: AppColors.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.neonCyan, size: 14),
                      onTap: _resetToHome,
                    ),
                    const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
                    for (final root in categoryTree) ...[
                      if (root.children.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: AppColors.surfaceCard,
                          child: Text(
                            root.displayName.toUpperCase(),
                            style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                        for (final child in root.children)
                          ListTile(
                            dense: true,
                            leading: Icon(child.icon, color: AppColors.textMuted, size: 15),
                            title: Text(child.displayName, style: const TextStyle(color: AppColors.textWhite, fontSize: 11.5)),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.borderLight, size: 14),
                            onTap: () => _selectFilter(child.slug),
                          ),
                        const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
                      ] else ...[
                        ListTile(
                          dense: true,
                          leading: Icon(root.icon, color: AppColors.textMuted, size: 15),
                          title: Text(root.displayName, style: const TextStyle(color: AppColors.textWhite, fontSize: 11.5)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.borderLight, size: 14),
                          onTap: () => _selectFilter(root.slug),
                        ),
                        const Divider(height: 1, thickness: 1, color: AppColors.borderLight),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Thanh công cụ vuông góc bên phải trên màn hình Desktop
  Widget _buildDesktopUtilityToolbar() {
    return Container(
      width: 76,
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(left: BorderSide(color: AppColors.borderLight, width: 1.5)),
      ),
      child: Column(
        children: [
          _buildUtilityToolItem(Icons.psychology_outlined, 'Hỗ trợ AI', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAdvisorScreen()));
          }),
          _buildUtilityToolItem(Icons.build_outlined, 'Xây dựng PC', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BuildPcScreen()));
          }),
          _buildUtilityToolItem(Icons.card_giftcard, 'Khuyến mãi', () {
            _selectFilter('Khuyến Mãi');
          }),
          _buildUtilityToolItem(Icons.balance, 'So sánh', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen()));
          }),
          _buildUtilityToolItem(Icons.calculate_outlined, 'Dự tính', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetEstimatorScreen()));
          }),
          _buildUtilityToolItem(Icons.chat_bubble_outline, 'Chat', () {
            _showContactSupportDialog('Chat Hỗ Trợ Kỹ Thuật');
          }),
          _buildUtilityToolItem(Icons.phone_in_talk_outlined, 'Hotline', () {
            _showContactSupportDialog('Hotline CSKH: 086 830 2123');
          }),
          _buildUtilityToolItem(Icons.forum_outlined, 'Zalo', () {
            _showContactSupportDialog('Zalo: JOPPE Gaming Store');
          }),
        ],
      ),
    );
  }

  Widget _buildUtilityToolItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.neonCyan, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSupportDialog(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(16))),
        title: Row(
          children: [
            const Icon(Icons.support_agent, color: AppColors.neonCyan, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(color: AppColors.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'JOPPE Store sẵn sàng hỗ trợ bạn 24/7:',
              style: TextStyle(color: AppColors.textWhite, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              color: AppColors.primaryDark,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📞 Hotline: 086 830 2123', style: TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('💬 Zalo: 086 830 2123 (Joppe CSKH)', style: TextStyle(color: AppColors.textWhite, fontSize: 12)),
                  SizedBox(height: 4),
                  Text('✉️ Email: cskh@tncstore.vn', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÓNG', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
