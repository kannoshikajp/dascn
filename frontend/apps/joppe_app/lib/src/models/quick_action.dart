import 'package:flutter/material.dart';

/// Model đại diện cho các nút tiện ích nhanh góc vuông (Quick Action Tiles)
class QuickActionItem {
  final String id;
  final String title;
  final IconData icon;
  final String? badgeText;
  final String route;
  final bool isExternal;

  const QuickActionItem({
    required this.id,
    required this.title,
    required this.icon,
    this.badgeText,
    this.route = '',
    this.isExternal = false,
  });
}
