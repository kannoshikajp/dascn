import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/catalog_service.dart';

/// Navigation Bar gồm nút "DANH MỤC SẢN PHẨM" và dải các tab đồng bộ động theo API
class NavigationTabsBar extends StatefulWidget {
  final VoidCallback? onCategoryMenuTap;
  final ValueChanged<String>? onTabSelected;

  const NavigationTabsBar({
    super.key,
    this.onCategoryMenuTap,
    this.onTabSelected,
  });

  @override
  State<NavigationTabsBar> createState() => _NavigationTabsBarState();
}

class _NavigationTabsBarState extends State<NavigationTabsBar> {
  int _selectedTabIndex = 0;

  List<String> _getDynamicTabs() {
    final catalog = CatalogService();
    final tabs = <String>['Build PC', 'So Sánh', 'Dự Tính'];

    // Lấy các phân loại & danh mục chính đồng bộ trực tiếp từ cây danh mục API
    final tree = catalog.categoryTree;
    for (final root in tree) {
      if (root.children.isNotEmpty) {
        for (final child in root.children) {
          final name = child.displayName.isNotEmpty ? child.displayName : child.categoryName;
          if (!tabs.contains(name) && tabs.length < 12) {
            tabs.add(name);
          }
        }
      } else {
        final name = root.displayName.isNotEmpty ? root.displayName : root.categoryName;
        if (!tabs.contains(name) && tabs.length < 12) {
          tabs.add(name);
        }
      }
    }

    if (!tabs.contains('Khuyến Mãi')) {
      tabs.add('Khuyến Mãi');
    }

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: [
          // Nút "DANH MỤC SẢN PHẨM" bo góc nổi bật bên trái
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onCategoryMenuTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu, color: AppColors.textOnAction, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'DANH MỤC SẢN PHẨM',
                    style: TextStyle(
                      color: AppColors.textOnAction,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Các tab danh mục đồng bộ động từ API
          ...() {
            final dynamicTabs = _getDynamicTabs();
            return List.generate(dynamicTabs.length, (index) {
              final tabName = dynamicTabs[index];
              final isSelected = _selectedTabIndex == index;
              final isPromo = tabName == 'Khuyến Mãi';

              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9999),
                  onTap: () {
                    setState(() => _selectedTabIndex = index);
                    widget.onTabSelected?.call(tabName);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPromo) ...[
                          const Icon(Icons.local_fire_department, color: Color(0xFFD97706), size: 14),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          tabName,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : (isPromo ? const Color(0xFFD97706) : AppColors.textPrimary),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        }(),
        ],
      ),
    );
  }
}
