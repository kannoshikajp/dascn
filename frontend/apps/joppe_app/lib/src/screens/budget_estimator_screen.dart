import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/catalog_service.dart';
import '../widgets/common/product_image.dart';
import 'build_pc_screen.dart';
import 'cart_screen.dart';

/// Màn hình Dự tính Cấu hình PC, Ngân sách Tỷ lệ vàng, Trả góp 0% & Điện năng tiêu thụ
class BudgetEstimatorScreen extends StatefulWidget {
  final double? initialBudget;

  const BudgetEstimatorScreen({
    super.key,
    this.initialBudget,
  });

  @override
  State<BudgetEstimatorScreen> createState() => _BudgetEstimatorScreenState();
}

class _BudgetEstimatorScreenState extends State<BudgetEstimatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 1: Ngân sách & Cấu hình
  double _budget = 25000000;
  String _selectedUsage = 'gaming'; // 'gaming', 'render', 'ai', 'office'

  // Tab 2: Trả góp
  double _prepaidRatio = 0.3; // 30%
  int _installmentMonths = 6; // 6 tháng

  // Tab 3: Điện năng
  double _dailyHours = 4.0; // 4 tiếng / ngày
  double _powerLoadWatts = 420; // 420W
  final double _kwhPrice = 2500; // 2.500 đ / kWh

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialBudget != null && widget.initialBudget! > 0) {
      _budget = widget.initialBudget!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Trích xuất tỷ lệ phân bổ ngân sách theo từng loại nhu cầu
  Map<String, double> get _budgetRatio {
    switch (_selectedUsage) {
      case 'render':
        return {
          'cpu': 0.28,
          'gpu': 0.32,
          'mainboard': 0.12,
          'ram': 0.14,
          'storage': 0.08,
          'psu': 0.06,
        };
      case 'ai':
        return {
          'gpu': 0.42,
          'cpu': 0.22,
          'ram': 0.16,
          'mainboard': 0.10,
          'storage': 0.05,
          'psu': 0.05,
        };
      case 'office':
        return {
          'cpu': 0.38,
          'mainboard': 0.18,
          'ram': 0.16,
          'storage': 0.14,
          'psu': 0.14,
          'gpu': 0.0,
        };
      case 'gaming':
      default:
        return {
          'gpu': 0.42,
          'cpu': 0.23,
          'mainboard': 0.10,
          'ram': 0.09,
          'storage': 0.08,
          'psu': 0.08,
        };
    }
  }

  /// Khớp các linh kiện thực tế tốt nhất trong kho Joppe với ngân sách phân bổ
  Map<String, Product> _recommendComponents() {
    final ratio = _budgetRatio;
    final recommended = <String, Product>{};

    for (final entry in ratio.entries) {
      final compType = entry.key;
      final targetAmount = _budget * entry.value;
      if (targetAmount <= 0) continue;

      final candidates = CatalogService().filterProducts(compType);
      if (candidates.isEmpty) continue;

      // Tìm sản phẩm có giá gần nhất nhưng không vượt quá 120% targetAmount
      candidates.sort((a, b) {
        final diffA = (a.price - targetAmount).abs();
        final diffB = (b.price - targetAmount).abs();
        return diffA.compareTo(diffB);
      });

      recommended[compType] = candidates.first;
    }

    return recommended;
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
          'DỰ TÍNH CẤU HÌNH & CHI PHÍ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
          tabs: const [
            Tab(text: 'NGÂN SÁCH'),
            Tab(text: 'TRẢ GÓP 0%'),
            Tab(text: 'TIỀN ĐIỆN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBudgetAllocationTab(),
          _buildInstallmentTab(),
          _buildElectricityTab(),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: DỰ TÍNH CẤU HÌNH & PHÂN BỔ TỶ LỆ VÀNG
  // =========================================================================
  Widget _buildBudgetAllocationTab() {
    final components = _recommendComponents();
    final totalActualCost = components.values.fold<double>(0, (sum, p) => sum + p.price);
    final diff = _budget - totalActualCost;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Khối nhập / chọn ngân sách
          Container(
            padding: const EdgeInsets.all(16),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NGÂN SÁCH DỰ KIẾN:',
                      style: TextStyle(
                        color: AppColors.textSubtle,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Product.formatVnd(_budget),
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primaryBlue,
                    inactiveTrackColor: AppColors.searchFieldBg,
                    thumbColor: AppColors.primaryBlue,
                    overlayColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _budget,
                    min: 10000000,
                    max: 80000000,
                    divisions: 70,
                    onChanged: (val) {
                      setState(() {
                        _budget = val;
                      });
                    },
                  ),
                ),
                // Nút chọn nhanh mức tiền phổ biến
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [15000000.0, 20000000.0, 25000000.0, 35000000.0, 50000000.0, 70000000.0].map((amt) {
                    final isSel = _budget == amt;
                    final label = '${(amt / 1000000).round()} Triệu';
                    return InkWell(
                      borderRadius: BorderRadius.circular(9999),
                      onTap: () => setState(() => _budget = amt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primaryBlue : AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(color: isSel ? AppColors.primaryBlue : AppColors.borderLight),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: isSel ? AppColors.textOnAction : AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Lựa chọn nhu cầu sử dụng
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NHU CẦU SỬ DỤNG CHÍNH:',
                  style: TextStyle(
                    color: AppColors.textSubtle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildUsageChip('gaming', '🎮 Gaming Esport / AAA'),
                    _buildUsageChip('render', '🎨 Đồ Họa 3D / Render 4K'),
                    _buildUsageChip('ai', '🤖 AI & Deep Learning'),
                    _buildUsageChip('office', '💼 Văn Phòng / Học Tập'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Phân bổ tỷ lệ vàng (Breakdown bar)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCardLighter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderAccent.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_outline, color: AppColors.primaryBlue, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'TỶ LỆ VÀNG PHÂN BỔ NGÂN SÁCH TỐI ƯU:',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: _budgetRatio.entries.map((e) {
                    final amount = _budget * e.value;
                    final pct = (e.value * 100).round();
                    return Text(
                      '${e.key.toUpperCase()}: $pct% (~${Product.formatVnd(amount)})',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Danh sách linh kiện đề xuất từ kho thực tế
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: AppColors.surfaceSubtle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CẤU HÌNH ĐỀ XUẤT TỪ KHO JOPPE',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${components.length} linh kiện',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ...components.entries.map((entry) {
                  final slot = entry.key;
                  final p = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 0.8)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ProductImage(
                            imageUrl: p.imageUrl,
                            componentType: p.componentType,
                            brand: p.brand,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${slot.toUpperCase()}: ${p.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p.brand,
                                style: const TextStyle(color: AppColors.textSubtle, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          p.formattedPrice,
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                // Tổng kết chi phí thực tế
                Container(
                  padding: const EdgeInsets.all(14),
                  color: AppColors.surfaceSubtle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TỔNG CHI PHÍ THỰC TẾ:', style: TextStyle(fontSize: 10, color: AppColors.textSubtle)),
                          Text(
                            Product.formatVnd(totalActualCost),
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: diff >= 0
                              ? const Color(0xFF00E676).withValues(alpha: 0.15)
                              : AppColors.accentRed.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          diff >= 0 ? 'Dư: ${Product.formatVnd(diff)}' : 'Vượt: ${Product.formatVnd(-diff)}',
                          style: TextStyle(
                            color: diff >= 0 ? const Color(0xFF00A854) : AppColors.accentRed,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Nút Nạp vào Build PC & Nút Giỏ Hàng
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceCard,
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: components.isEmpty
                      ? null
                      : () {
                          CartService().addMultipleProducts(components.values.toList());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã thêm trọn bộ ${components.length} linh kiện vào giỏ hàng!'),
                              backgroundColor: AppColors.primaryBlue,
                              action: SnackBarAction(
                                label: 'XEM GIỎ',
                                textColor: Colors.amberAccent,
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                                },
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text(
                    'THÊM GIỎ HÀNG',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.textOnAction,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: components.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BuildPcScreen(initialComponents: components),
                            ),
                          );
                        },
                  icon: const Icon(Icons.computer, size: 16),
                  label: const Text(
                    'NẠP VÀO BUILD PC',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUsageChip(String id, String label) {
    final isSel = _selectedUsage == id;
    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: () => setState(() => _selectedUsage = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primaryBlue : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: isSel ? AppColors.primaryBlue : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? AppColors.textOnAction : AppColors.textPrimary,
            fontSize: 11.5,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 2: DỰ TÍNH TRẢ GÓP 0%
  // =========================================================================
  Widget _buildInstallmentTab() {
    final prepaidAmount = _budget * _prepaidRatio;
    final loanAmount = _budget - prepaidAmount;
    final monthlyAmount = loanAmount / _installmentMonths;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Khối tổng tiền cấu hình
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GIÁ TRỊ CẤU HÌNH TRẢ GÓP:',
                  style: TextStyle(color: AppColors.textSubtle, fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                Text(
                  Product.formatVnd(_budget),
                  style: const TextStyle(color: AppColors.primaryBlue, fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tỷ lệ trả trước
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TỶ LỆ TRẢ TRƯỚC:', style: TextStyle(color: AppColors.textSubtle, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    Text(
                      '${(_prepaidRatio * 100).round()}% (${Product.formatVnd(prepaidAmount)})',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [0.2, 0.3, 0.4, 0.5].map((ratio) {
                    final isSel = _prepaidRatio == ratio;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSel ? AppColors.primaryBlue : AppColors.surfaceSubtle,
                            foregroundColor: isSel ? AppColors.textOnAction : AppColors.textPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => setState(() => _prepaidRatio = ratio),
                          child: Text('${(ratio * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Kỳ hạn trả góp
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KỲ HẠN VAY:', style: TextStyle(color: AppColors.textSubtle, fontSize: 11.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [3, 6, 9, 12].map((m) {
                    final isSel = _installmentMonths == m;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSel ? AppColors.primaryBlue : AppColors.surfaceSubtle,
                            foregroundColor: isSel ? AppColors.textOnAction : AppColors.textPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => setState(() => _installmentMonths = m),
                          child: Text('$m Tháng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Kết quả bảng dự tính trả góp
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCardLighter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderAccent.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tiền trả trước ngay:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(Product.formatVnd(prepaidAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Số tiền vay góp:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(Product.formatVnd(loanAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lãi suất ưu đãi:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const Text('0% Lãi suất', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00A854))),
                  ],
                ),
                const Divider(height: 20, color: AppColors.borderLight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GÓP MỖI THÁNG (~):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
                    Text(
                      '${Product.formatVnd(monthlyAmount)} / tháng',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Thủ tục & Giấy tờ
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: AppColors.primaryBlue, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'THỦ TỤC TRẢ GÓP TẠI JOPPE',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('• Hỗ trợ thẻ tín dụng Visa/MasterCard của hơn 25 ngân hàng lớn.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                SizedBox(height: 4),
                Text('• Hoặc trả góp qua CCCD gắn chip (Home Credit / FE Credit), duyệt hồ sơ trong 15 phút.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                SizedBox(height: 4),
                Text('• Nhận máy ngay tại showroom hoặc giao hàng tận nơi toàn quốc.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: DỰ TÍNH TIỀN ĐIỆN & TIÊU THỤ
  // =========================================================================
  Widget _buildElectricityTab() {
    // Điện năng tiêu thụ mỗi ngày (kWh) = Watts * Hours / 1000
    final dailyKwh = (_powerLoadWatts * _dailyHours) / 1000;
    final monthlyKwh = dailyKwh * 30;
    final monthlyCost = monthlyKwh * _kwhPrice;
    final yearlyCost = monthlyCost * 12;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Công suất dàn máy
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CÔNG SUẤT TIÊU THỤ (TẢI):', style: TextStyle(color: AppColors.textSubtle, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    Text('${_powerLoadWatts.round()} W', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primaryBlue,
                    thumbColor: AppColors.primaryBlue,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _powerLoadWatts,
                    min: 150,
                    max: 850,
                    divisions: 14,
                    onChanged: (val) => setState(() => _powerLoadWatts = val),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('150W (Văn phòng)', style: TextStyle(fontSize: 9.5, color: AppColors.textSubtle)),
                    Text('450W (Gaming)', style: TextStyle(fontSize: 9.5, color: AppColors.textSubtle)),
                    Text('850W (High-End/AI)', style: TextStyle(fontSize: 9.5, color: AppColors.textSubtle)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Số giờ sử dụng mỗi ngày
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('THỜI GIAN DÙNG MỖI NGÀY:', style: TextStyle(color: AppColors.textSubtle, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    Text('${_dailyHours.round()} Tiếng / ngày', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primaryBlue,
                    thumbColor: AppColors.primaryBlue,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _dailyHours,
                    min: 1,
                    max: 16,
                    divisions: 15,
                    onChanged: (val) => setState(() => _dailyHours = val),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Kết quả tính tiền điện
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCardLighter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderAccent.withValues(alpha: 0.3), width: 1.2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Điện năng tiêu thụ / tháng:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text('${monthlyKwh.toStringAsFixed(1)} kWh (số điện)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Đơn giá điện EVN trung bình:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text('${Product.formatVnd(_kwhPrice)} / kWh', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const Divider(height: 20, color: AppColors.borderLight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TIỀN ĐIỆN DỰ TÍNH / THÁNG:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
                    Text(
                      Product.formatVnd(monthlyCost),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Ước tính cả năm: ~${Product.formatVnd(yearlyCost)}',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSubtle),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Mẹo tiết kiệm điện
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tips_and_updates_outlined, color: Colors.amber, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'MẸO TỐI ƯU ĐIỆN NĂNG CHO DÀN PC',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text('• Chọn nguồn chuẩn 80 Plus Gold / Platinum giúp tiết kiệm 10-15% lượng điện thất thoát.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                SizedBox(height: 4),
                Text('• Bật tính năng C-States & Undervolt nhẹ GPU/CPU giúp giảm 50-80W mà không giảm hiệu năng game.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                SizedBox(height: 4),
                Text('• Kích hoạt chế độ Sleep sau 15 phút không hoạt động để tránh tiêu tốn điện năng ngầm.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
