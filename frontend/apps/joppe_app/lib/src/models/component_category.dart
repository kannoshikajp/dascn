import 'package:flutter/material.dart';

/// Danh mục linh kiện phần cứng công nghệ phục vụ sàn thương mại và tính năng Build PC
class ComponentCategory {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final IconData icon;
  final bool isRequiredForBuild;
  final int displayOrder;
  final String? slug;

  const ComponentCategory({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.icon,
    this.isRequiredForBuild = false,
    this.displayOrder = 0,
    this.slug,
  });
}
