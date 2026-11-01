import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';

/// Helper for grouping and presenting RBAC permissions by business domain / type.
class RbacCategoryHelper {
  static const Map<String, IconData> _icons = {
    'AUTH': Icons.lock_outline,
    'USER': Icons.people_outline,
    'ADDRESS': Icons.location_on_outlined,
    'CATALOG': Icons.category_outlined,
    'INVENTORY': Icons.warehouse_outlined,
    'CART': Icons.shopping_cart_outlined,
    'PROMOTION': Icons.discount_outlined,
    'ORDER': Icons.receipt_long_outlined,
    'PAYMENT': Icons.payment_outlined,
    'SHIPMENT': Icons.local_shipping_outlined,
    'RETURN': Icons.assignment_return_outlined,
    'REVIEW': Icons.star_outline,
    'PC_BUILD': Icons.desktop_windows_outlined,
    'ROLE': Icons.admin_panel_settings_outlined,
  };

  static const Map<String, String> _enLabels = {
    'AUTH': 'Authentication',
    'USER': 'User Management',
    'ADDRESS': 'Address & Shipping',
    'CATALOG': 'Catalog & Products',
    'INVENTORY': 'Inventory & Stock',
    'CART': 'Shopping Cart',
    'PROMOTION': 'Promotions & Discounts',
    'ORDER': 'Orders & Tracking',
    'PAYMENT': 'Payment Processing',
    'SHIPMENT': 'Shipment & Logistics',
    'RETURN': 'Returns & Refunds',
    'REVIEW': 'Reviews & Ratings',
    'PC_BUILD': 'PC Builder',
    'ROLE': 'Role & Permissions',
  };

  static const Map<String, String> _viLabels = {
    'AUTH': 'Xác thực & Bảo mật',
    'USER': 'Quản lý Người dùng',
    'ADDRESS': 'Địa chỉ & Giao hàng',
    'CATALOG': 'Danh mục & Sản phẩm',
    'INVENTORY': 'Kho hàng & Nhập kho',
    'CART': 'Giỏ hàng',
    'PROMOTION': 'Khuyến mãi & Ưu đãi',
    'ORDER': 'Đơn hàng & Theo dõi',
    'PAYMENT': 'Cổng Thanh toán',
    'SHIPMENT': 'Vận chuyển',
    'RETURN': 'Đổi trả & Hoàn tiền',
    'REVIEW': 'Đánh giá & Bình luận',
    'PC_BUILD': 'Cấu hình PC',
    'ROLE': 'Vai trò & Quyền hạn',
  };

  /// Extracts the grouping key from a permission name (e.g. CATALOG_READ -> CATALOG).
  static String extractGroup(String permissionName) {
    final upper = permissionName.toUpperCase();
    if (upper.startsWith('PC_BUILD_')) return 'PC_BUILD';
    final idx = upper.indexOf('_');
    if (idx != -1) {
      return upper.substring(0, idx);
    }
    return 'GENERAL';
  }

  /// Returns the localized title of a permission type/category.
  static String getCategoryTitle(String groupKey, {bool isVi = false}) {
    if (isVi) {
      return _viLabels[groupKey] ?? groupKey;
    }
    return _enLabels[groupKey] ?? groupKey;
  }

  /// Returns a category icon.
  static IconData getCategoryIcon(String groupKey) {
    return _icons[groupKey] ?? Icons.vpn_key_outlined;
  }

  /// Groups a list of PermissionItem objects by type.
  static Map<String, List<PermissionItem>> groupPermissions(List<PermissionItem> permissions) {
    final map = <String, List<PermissionItem>>{};
    for (final p in permissions) {
      final grp = extractGroup(p.permissionName);
      map.putIfAbsent(grp, () => []).add(p);
    }
    return map;
  }
}
