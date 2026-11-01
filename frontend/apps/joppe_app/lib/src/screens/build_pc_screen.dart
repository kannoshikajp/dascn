import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/component_category.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/catalog_service.dart';
import '../services/store_domain_api_service.dart';
import '../widgets/common/cyber_effects.dart';
import '../widgets/common/product_image.dart';
import 'ai_advisor_screen.dart';
import 'budget_estimator_screen.dart';
import 'auth_screen.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';

/// Màn hình Xây dựng cấu hình PC (Build PC Builder)
class BuildPcScreen extends StatefulWidget {
  final Map<String, Product>? initialComponents;
  const BuildPcScreen({super.key, this.initialComponents});

  @override
  State<BuildPcScreen> createState() => _BuildPcScreenState();
}

class _BuildPcScreenState extends State<BuildPcScreen> {
  // Bản đồ lưu trữ linh kiện đã chọn theo categoryId
  final Map<String, Product> _selectedComponents = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialComponents != null) {
      _selectedComponents.addAll(widget.initialComponents!);
    }
    CatalogService().addListener(_onCatalogChanged);
    // Tự động đồng bộ cây danh mục và sản phẩm từ API
    CatalogService().fetchCatalog();
  }

  @override
  void dispose() {
    CatalogService().removeListener(_onCatalogChanged);
    super.dispose();
  }

  void _onCatalogChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Các linh kiện phần cứng trọng tâm trong cấu hình PC lấy từ danh mục API
  List<ComponentCategory> get _buildSlots => CatalogService().buildSlots;

  double get _totalPriceVnd {
    return _selectedComponents.values.fold(0.0, (sum, item) => sum + item.price);
  }

  String get _formattedTotalPriceVnd => Product.formatVnd(_totalPriceVnd);

  /// Ước tính công suất tiêu thụ điện (Wattage) của các linh kiện đã chọn
  int get _estimatedWattage {
    if (_selectedComponents.isEmpty) return 0;
    int wattage = 70; // Tải cơ bản: Mainboard, RAM DDR5, Ổ SSD NVMe, Quạt case

    final cpu = _selectedComponents['cpu'];
    if (cpu != null) {
      final name = cpu.name.toLowerCase();
      if (name.contains('ultra 9') || name.contains('i9') || name.contains('ryzen 9') || name.contains('9950x') || name.contains('9900x')) {
        wattage += 250;
      } else if (name.contains('ultra 7') || name.contains('i7') || name.contains('ryzen 7') || name.contains('9800x3d') || name.contains('7800x3d')) {
        wattage += 180;
      } else if (name.contains('ultra 5') || name.contains('i5') || name.contains('ryzen 5')) {
        wattage += 125;
      } else {
        wattage += 105;
      }
    }

    final gpu = _selectedComponents['gpu'] ?? _selectedComponents['vga'];
    if (gpu != null) {
      final name = gpu.name.toLowerCase();
      if (name.contains('4090') || name.contains('5090')) {
        wattage += 450;
      } else if (name.contains('4080') || name.contains('5080') || name.contains('7900 xtx') || name.contains('7900 xt')) {
        wattage += 320;
      } else if (name.contains('4070 ti') || name.contains('4070 super') || name.contains('4070') || name.contains('7800 xt')) {
        wattage += 220;
      } else if (name.contains('4060 ti') || name.contains('4060') || name.contains('7600')) {
        wattage += 160;
      } else {
        wattage += 200;
      }
    }

    final cooler = _selectedComponents['cooler'] ?? _selectedComponents['t'] ?? _selectedComponents['tản nhiệt'];
    if (cooler != null) {
      wattage += cooler.name.toLowerCase().contains('aio') || cooler.name.toLowerCase().contains('nước') ? 30 : 15;
    }

    return wattage;
  }

  /// Công suất bộ nguồn PSU tối thiểu khuyến nghị (có dự phòng xung đột tải đột ngột 35-40%)
  int get _recommendedPsuWattage {
    final w = _estimatedWattage;
    if (w == 0) return 0;
    final target = (w * 1.4).round();
    if (target <= 550) return 550;
    if (target <= 650) return 650;
    if (target <= 750) return 750;
    if (target <= 850) return 850;
    if (target <= 1000) return 1000;
    return 1200;
  }

  /// Công suất thực tế của nguồn PSU đang được chọn trong cấu hình
  int? get _selectedPsuWattage {
    final psu = _selectedComponents['psu'] ?? _selectedComponents['n'] ?? _selectedComponents['nguồn'];
    if (psu == null) return null;
    final reg = RegExp(r'(\d{3,4})\s*W', caseSensitive: false);
    final match = reg.firstMatch(psu.name);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  void _openComponentPicker(ComponentCategory slot) {
    // 1. Tự động đồng bộ sản phẩm từ API theo danh mục nếu có
    final filterKey = slot.slug ?? slot.id;
    int? targetCatId = int.tryParse(slot.id);
    if (targetCatId == null) {
      void findId(List<dynamic> nodes) {
        for (final n in nodes) {
          final nSlug = n.slug.toLowerCase().replaceAll(RegExp(r'^/+'), '').trim();
          final nName = n.categoryName.toLowerCase().trim();
          if (nSlug == filterKey.toLowerCase() ||
              nName == slot.name.toLowerCase() ||
              nName == slot.shortName.toLowerCase()) {
            targetCatId = n.id;
            return;
          }
          if (n.children.isNotEmpty) findId(n.children);
        }
      }
      findId(CatalogService().categoryTree);
    }

    if (targetCatId != null) {
      CatalogService().queryApiProducts(categoryId: targetCatId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ListenableBuilder(
              listenable: CatalogService(),
              builder: (context, _) {
                final candidates = CatalogService().filterProducts(slot.slug ?? slot.id);
                final filteredCandidates = candidates.where((p) {
                  if (searchQuery.isEmpty) return true;
                  final q = searchQuery.toLowerCase();
                  return p.name.toLowerCase().contains(q) ||
                      p.brand.toLowerCase().contains(q) ||
                      p.specs.any((s) => s.toLowerCase().contains(q));
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
                          Icon(slot.icon, color: AppColors.textOnAction, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'CHỌN ${slot.name.toUpperCase()}',
                              style: const TextStyle(
                                color: AppColors.textOnAction,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
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
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm ${slot.shortName}...',
                          hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
                          filled: true,
                          fillColor: AppColors.searchFieldBg,
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(14)),
                            borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(14)),
                            borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(14)),
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
                    // Danh sách linh kiện tương thích
                    Expanded(
                      child: filteredCandidates.isEmpty
                          ? const Center(
                              child: Text(
                                'Không tìm thấy linh kiện phù hợp.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              itemCount: filteredCandidates.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final product = filteredCandidates[index];
                                final isCurrent = _selectedComponents[slot.id]?.id == product.id;

                                return Container(
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                                    border: Border.all(
                                      color: isCurrent ? AppColors.primaryBlue : AppColors.borderLight,
                                      width: isCurrent ? 1.8 : 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(10),
                                    leading: Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.primaryDark,
                                      child: ProductImage(
                                        imageUrl: product.imageUrl,
                                        componentType: product.componentType,
                                        brand: product.brand,
                                        fit: BoxFit.cover,
                                        width: 60,
                                        height: 60,
                                      ),
                                    ),
                                    title: Text(
                                      product.name,
                                      style: const TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                color: AppColors.primaryDark,
                                                child: Text(
                                                  product.brand,
                                                  style: const TextStyle(
                                                    color: AppColors.neonCyan,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'BH: ${product.warrantyMonths}T',
                                                style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            product.formattedPrice,
                                            style: const TextStyle(
                                              color: AppColors.neonCyan,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isCurrent ? AppColors.accentRed : AppColors.primaryBlue,
                                        foregroundColor: AppColors.textOnAction,
                                        shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(14))),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (isCurrent) {
                                            _selectedComponents.remove(slot.id);
                                          } else {
                                            _selectedComponents[slot.id] = product;
                                          }
                                        });
                                        Navigator.pop(ctx);
                                      },
                                      child: Text(
                                        isCurrent ? 'BỎ CHỌN' : 'CHỌN',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
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
              const Flexible(
                child: Text(
                  'XÂY DỰNG CẤU HÌNH PC',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Dự tính chi phí & trả góp',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.calculate_outlined, color: AppColors.primaryBlue, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BudgetEstimatorScreen(
                    initialBudget: _totalPriceVnd > 0 ? _totalPriceVnd : null,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Trang chủ JOPPE',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.home_outlined, color: AppColors.neonCyan, size: 20),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          IconButton(
            tooltip: 'Dự tính chi phí & trả góp',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.calculate_outlined, color: AppColors.neonCyan, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetEstimatorScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới cấu hình',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary, size: 20),
            onPressed: _selectedComponents.isEmpty
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surfaceCard,
                        shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(24))),
                        title: const Text('Làm mới cấu hình?', style: TextStyle(color: AppColors.textPrimary)),
                        content: const Text(
                          'Thao tác này sẽ xóa toàn bộ linh kiện bạn đã chọn.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentRed,
                              foregroundColor: AppColors.textOnAction,
                              shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(14))),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedComponents.clear();
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Xác nhận'),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner tóm tắt tiến trình Build PC
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.surfaceCard,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.neonCyan, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Đã chọn: ${_selectedComponents.length}/${_buildSlots.length} linh kiện chính',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedComponents.length == _buildSlots.length
                      ? 'HOÀN CHỈNH'
                      : 'Đang xây dựng',
                  style: TextStyle(
                    color: _selectedComponents.length == _buildSlots.length
                        ? Colors.greenAccent
                        : Colors.amberAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderLight),

          // 1. Thước đo công suất tiêu thụ & Khuyến nghị nguồn PSU
          _buildWattageMeterBar(),

          // 2. Banner trợ lý AI Gemini & Thẩm định cấu hình / Check Bottleneck
          _buildAiAdvisorBanner(),
          _buildBudgetEstimatorBanner(),

          // Danh sách 8 slot linh kiện
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _buildSlots.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final slot = _buildSlots[index];
                final selectedProduct = _selectedComponents[slot.id];

                return _buildSlotCard(slot, selectedProduct);
              },
            ),
          ),

          // Bottom Bar tổng giá và nút thao tác
          _buildBottomSummaryBar(),
        ],
      ),
    );
  }

  Widget _buildSlotCard(ComponentCategory slot, Product? product) {
    final isSelected = product != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.4) : AppColors.borderLight,
          width: 1.2,
        ),
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
        child: isSelected
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ảnh linh kiện
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsScreen(product: product),
                        ),
                      );
                    },
                    child: Container(
                      width: 70,
                      height: 70,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: ProductImage(
                        imageUrl: product.imageUrl,
                        componentType: product.componentType,
                        brand: product.brand,
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Thông tin linh kiện
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              color: AppColors.primaryBlue,
                              child: Text(
                                slot.shortName,
                                style: const TextStyle(
                                  color: AppColors.textOnAction,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product.brand,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(product: product),
                              ),
                            );
                          },
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.formattedPrice,
                          style: const TextStyle(
                            color: AppColors.neonCyan,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nút thay đổi & nút xóa
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Thay đổi linh kiện',
                        icon: const Icon(Icons.edit, color: AppColors.neonCyan, size: 20),
                        onPressed: () => _openComponentPicker(slot),
                      ),
                      IconButton(
                        tooltip: 'Xóa khỏi cấu hình',
                        icon: const Icon(Icons.delete_outline, color: AppColors.accentRed, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedComponents.remove(slot.id);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Icon(slot.icon, color: AppColors.primaryBlue, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.name,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slot.description,
                          style: const TextStyle(
                            color: AppColors.textSubtle,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.textOnAction,
                      shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(14))),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _openComponentPicker(slot),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      'CHỌN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Thước đo công suất tiêu thụ điện & Khuyến nghị bộ nguồn an toàn
  Widget _buildWattageMeterBar() {
    final wattage = _estimatedWattage;
    final recommended = _recommendedPsuWattage;
    final selectedPsu = _selectedPsuWattage;

    final ratio = recommended > 0 ? (wattage / recommended).clamp(0.0, 1.0) : 0.0;
    final bool isUnderpowered = selectedPsu != null && selectedPsu < recommended;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(
          color: isUnderpowered ? AppColors.wattageDanger : AppColors.borderLight,
          width: isUnderpowered ? 1.5 : 1,
        ),
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
            children: [
              const Icon(Icons.bolt, color: AppColors.neonCyan, size: 15),
              const SizedBox(width: 4),
              const Text(
                'TẢI:',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$wattage W',
                style: const TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  recommended > 0 ? 'PSU ≥ ${recommended}W' : 'Chưa tải linh kiện',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: AppColors.searchFieldBg,
              valueColor: AlwaysStoppedAnimation<Color>(
                isUnderpowered
                    ? AppColors.wattageDanger
                    : (wattage > 600 ? AppColors.wattageWarning : AppColors.wattageSafe),
              ),
            ),
          ),
          if (isUnderpowered) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.wattageDanger, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Cảnh báo: Nguồn bạn chọn (${selectedPsu}W) thấp hơn khuyến nghị (${recommended}W) cho cấu hình này!',
                    style: const TextStyle(color: AppColors.wattageDanger, fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ] else if (selectedPsu != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.wattageSafe, size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Nguồn đã chọn (${selectedPsu}W) đủ tải an toàn cho toàn bộ hệ thống.',
                    style: const TextStyle(color: AppColors.wattageSafe, fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Banner tương tác Trợ lý AI Gemini: Hỏi gợi ý cấu hình hoặc thẩm định Bottleneck khi đã chọn linh kiện
  Widget _buildBudgetEstimatorBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BudgetEstimatorScreen(
                initialBudget: _totalPriceVnd > 0 ? _totalPriceVnd : null,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calculate_outlined, color: AppColors.primaryBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dự tính ngân sách & Trả góp 0%',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _totalPriceVnd > 0
                          ? 'Dự tính trả góp ~/tháng & Tiền điện'
                          : 'Tự động tính phân bổ tỷ lệ vàng theo ngân sách & nhu cầu',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSubtle, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiAdvisorBanner() {
    final hasSelection = _selectedComponents.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TactilePress(
        onTap: () {
          if (hasSelection) {
            _runAiBottleneckCheck();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BudgetEstimatorScreen(),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceCardLighter,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.all(color: AppColors.borderAccent.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cần gợi ý cấu hình? Hỏi Trợ lý AI Gemini 3.5 Flash',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasSelection
                          ? 'AI Thẩm định cấu hình đã chọn, kiểm tra tương thích & Bottleneck'
                          : 'Tư vấn thông minh dựa trên ngân sách & tựa game của bạn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.neonCyan, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _runAiBottleneckCheck() {
    if (_selectedComponents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất CPU hoặc Card đồ họa để AI thẩm định!'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Chào trợ lý AI Joppe! Nhờ bạn thẩm định và đánh giá cấu hình PC tôi đang build:');
    _selectedComponents.forEach((slot, product) {
      buffer.writeln('- ${slot.toUpperCase()}: ${product.name} (Giá: ${product.formattedPrice})');
    });
    buffer.writeln('Tổng chi phí dự kiến: $_formattedTotalPriceVnd.');
    buffer.writeln('Công suất tiêu thụ ước tính: ${_estimatedWattage}W (Khuyến nghị PSU: ${_recommendedPsuWattage}W).');
    buffer.writeln('\nYêu cầu phân tích:');
    buffer.writeln('1. Độ tương thích phần cứng & Tỉ lệ nghẽn cổ chai CPU - VGA (Bottleneck index ước tính %).');
    buffer.writeln('2. Hiệu năng chiến game thực tế (Esports, AAA 1080p / 2K / 4K) & Render đồ họa / AI.');
    buffer.writeln('3. Lời khuyên có cần đổi hoặc nâng cấp linh kiện nào để tối ưu chi phí và sức mạnh không.');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAdvisorScreen(
          initialPrompt: buffer.toString(),
        ),
      ),
    );
  }

  void _saveBuildToAccount() async {
    if (_selectedComponents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 linh kiện để lưu cấu hình PC!'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    if (!AuthService().isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng đăng nhập để đồng bộ và lưu cấu hình PC vào tài khoản!'),
          backgroundColor: AppColors.primaryBlue,
          action: SnackBarAction(
            label: 'ĐĂNG NHẬP',
            textColor: Colors.amberAccent,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
          ),
        ),
      );
      return;
    }

    final componentsData = <String, dynamic>{};
    _selectedComponents.forEach((slot, product) {
      componentsData[slot] = {
        'id': product.id,
        'name': product.name,
        'price': product.price,
      };
    });

    final res = await StoreDomainApiService().saveBuild({
      'name': 'Dàn PC Custom ${DateTime.now().day}/${DateTime.now().month} (${_estimatedWattage}W)',
      'totalPrice': _totalPriceVnd,
      'estimatedWattage': _estimatedWattage,
      'components': componentsData,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.isSuccess ? 'Đã lưu cấu hình PC thành công vào tài khoản cloud!' : 'Đã lưu cấu hình PC vào thiết bị.'),
          backgroundColor: AppColors.primaryBlue,
        ),
      );
    }
  }

  Widget _buildBottomSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 2),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TỔNG CHI PHÍ DỰ KIẾN',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bảo hành chính hãng từng món',
                        style: TextStyle(
                          color: AppColors.textSubtle,
                          fontSize: 10,
                        ),
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
                      _formattedTotalPriceVnd,
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(14))),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _selectedComponents.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _selectedComponents.clear();
                            });
                          },
                    child: const Text('LÀM MỚI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Lưu cấu hình vào tài khoản (POST /api/v1/pc-builder/save)',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceCard,
                    shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(14))),
                    side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.neonCyan, size: 20),
                  onPressed: _selectedComponents.isEmpty ? null : _saveBuildToAccount,
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.textOnAction,
                      shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(Radius.circular(14))),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _selectedComponents.isEmpty
                        ? null
                        : () {
                            CartService().addMultipleProducts(_selectedComponents.values.toList());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã thêm trọn bộ cấu hình (${_selectedComponents.length} món) vào giỏ hàng!',
                                ),
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
                      'THÊM VÀO GIỎ HÀNG',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
