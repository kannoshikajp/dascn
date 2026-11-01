import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

/// Atom: Individual sidebar navigation item.
class SidebarNavItem extends JoppeNavigationDestination {
  const SidebarNavItem({
    required super.icon,
    super.selectedIcon,
    required super.label,
    super.group,
  });
}
