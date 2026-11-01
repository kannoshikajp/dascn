import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../localization/dashboard_localizations.dart';
import 'sidebar_nav_item.dart';

/// Organism: Builds structured sidebar navigation destinations based on atomic design.
class DashboardSidebar {
  DashboardSidebar._();

  /// 1. "Tổng quan": independent, top-level item (group: null).
  /// 2. "QUẢN LÝ BÁN HÀNG": "Đơn hàng & POS".
  /// 3. "HÀNG HÓA & KHO": "Sản phẩm", "Danh mục", "Tồn kho", "Phiếu nhập kho".
  /// 4. "ĐỐI TÁC": "Nhà cung cấp".
  /// 5. "CẤU HÌNH HỆ THỐNG": "Người dùng", "Phân quyền RBAC".
  static List<JoppeNavigationDestination> buildDestinations(BuildContext context) {
    final l10n = context.l10n;

    return [
      // 1. Independent Top-Level (NO group header)
      SidebarNavItem(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: l10n.navOverview,
        group: null,
      ),

      // 2. Section: QUẢN LÝ BÁN HÀNG
      SidebarNavItem(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long),
        label: l10n.navOrders,
        group: l10n.groupSales,
      ),
      SidebarNavItem(
        icon: const Icon(Icons.point_of_sale_outlined),
        selectedIcon: const Icon(Icons.point_of_sale),
        label: l10n.navPosCashier,
        group: l10n.groupSales,
      ),

      // 3. Section: HÀNG HÓA & KHO
      SidebarNavItem(
        icon: const Icon(Icons.inventory_2_outlined),
        selectedIcon: const Icon(Icons.inventory_2),
        label: l10n.navProducts,
        group: l10n.groupGoodsAndWarehouse,
      ),
      SidebarNavItem(
        icon: const Icon(Icons.category_outlined),
        selectedIcon: const Icon(Icons.category),
        label: l10n.navCategories,
        group: l10n.groupGoodsAndWarehouse,
      ),
      SidebarNavItem(
        icon: const Icon(Icons.warehouse_outlined),
        selectedIcon: const Icon(Icons.warehouse),
        label: l10n.navWarehouse,
        group: l10n.groupGoodsAndWarehouse,
      ),
      SidebarNavItem(
        icon: const Icon(Icons.input_rounded),
        selectedIcon: const Icon(Icons.input),
        label: l10n.navGoodsReceipts,
        group: l10n.groupGoodsAndWarehouse,
      ),

      // 4. Section: ĐỐI TÁC
      SidebarNavItem(
        icon: const Icon(Icons.business_outlined),
        selectedIcon: const Icon(Icons.business),
        label: l10n.navSuppliers,
        group: l10n.groupPartners,
      ),

      // 5. Section: CẤU HÌNH HỆ THỐNG
      SidebarNavItem(
        icon: const Icon(Icons.people_outline),
        selectedIcon: const Icon(Icons.people),
        label: l10n.navUsers,
        group: l10n.groupSystemConfig,
      ),
      SidebarNavItem(
        icon: const Icon(Icons.shield_outlined),
        selectedIcon: const Icon(Icons.shield),
        label: l10n.navRbacMatrix,
        group: l10n.groupSystemConfig,
      ),
      SidebarNavItem(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: l10n.navSettings,
        group: l10n.groupSystemConfig,
      ),
      SidebarNavItem(
        icon: const Icon(Icons.auto_awesome_outlined),
        selectedIcon: const Icon(Icons.auto_awesome),
        label: l10n.navAiAssistant,
        group: l10n.groupSystemConfig,
      ),
    ];
  }
}
