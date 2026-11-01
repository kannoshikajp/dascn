import 'package:flutter/material.dart';

/// Đại diện cho một nút danh mục phân cấp từ Joppe OpenAPI (/api/v1/categories/tree)
/// Hỗ trợ cấu trúc slug động, đếm sản phẩm, và mapping icon/loại linh kiện thông minh.
class CategoryNode {
  final int id;
  final int? parentId;
  final String categoryName;
  final String slug;
  final String? iconUrl;
  final bool isActive;
  final int productCount;
  final List<CategoryNode> children;

  const CategoryNode({
    required this.id,
    this.parentId,
    required this.categoryName,
    required this.slug,
    this.iconUrl,
    this.isActive = true,
    this.productCount = 0,
    this.children = const [],
  });

  factory CategoryNode.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final childList = <CategoryNode>[];
    if (rawChildren is List) {
      for (final c in rawChildren) {
        if (c is Map) {
          childList.add(CategoryNode.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }

    return CategoryNode(
      id: (json['id'] as num?)?.toInt() ?? 0,
      parentId: (json['parentId'] as num?)?.toInt(),
      categoryName: json['categoryName']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString(),
      isActive: json['isActive'] == true || json['isActive'] == null,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      children: childList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'categoryName': categoryName,
      'slug': slug,
      'iconUrl': iconUrl,
      'isActive': isActive,
      'productCount': productCount,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }

  /// Đường dẫn slug có tiền tố '/' (ví dụ: "/cpu", "/main", "/laptop-gaming")
  String get formattedSlug => slug.startsWith('/') ? slug : '/$slug';

  /// Tên hiển thị chi tiết (ví dụ: "CPU - Bộ Vi Xử Lý")
  String get displayName {
    final lowerSlug = slug.toLowerCase();
    final lowerName = categoryName.toLowerCase();

    if (lowerSlug == 'cpu' || lowerName == 'cpu') return 'CPU - Bộ Vi Xử Lý';
    if (lowerSlug == 'main' || lowerSlug == 'mainboard' || lowerName == 'mainboard') return 'Mainboard - Bo Mạch Chủ';
    if (lowerSlug == 'ram' || lowerName == 'ram') return 'RAM - Bộ Nhớ Trong';
    if (lowerSlug == 'gpu' || lowerSlug == 'vga' || lowerName == 'gpu' || lowerName == 'vga') return 'VGA - Card Đồ Họa';
    if (lowerSlug == 'ssd' || lowerSlug == 'hdd' || lowerSlug == 'storage' || lowerSlug == 's' || lowerName.contains('ổ cứng') || lowerName.contains('ssd')) {
      return 'SSD - Ổ Cứng Lưu Trữ';
    }
    if (lowerSlug == 'psu' || lowerSlug == 'power' || lowerSlug == 'n' || lowerName.contains('nguồn')) return 'PSU - Nguồn Máy Tính';
    if (lowerSlug == 'cooler' || lowerSlug == 'cooling' || lowerSlug == 't' || lowerName.contains('tản nhiệt') || lowerName.contains('tản')) {
      return 'Cooler - Tản Nhiệt PC';
    }
    if (lowerSlug == 'case' || lowerName.contains('vỏ case')) return 'Case - Vỏ Máy Tính';
    if (lowerSlug == 'laptop-gaming') return 'Laptop Gaming';
    if (lowerSlug == 'pc-ai') return 'PC Đồ Họa AI';
    if (lowerSlug == 'pc-gaming') return 'PC Gaming';
    if (lowerSlug == 'workstation') return 'Máy Trạm Workstation';
    if (lowerSlug == 'pc-part' || lowerSlug == 'linh-kien' || lowerName.contains('linh kien')) return 'Linh Kiện Máy Tính';
    if (lowerSlug == 'hang' || lowerName.contains('hang')) return 'Hãng Sản Xuất';
    if (lowerSlug == 'laptop') return 'Laptop';
    if (lowerSlug == 'pc') return 'Máy Tính Để Bàn PC';
    if (lowerSlug == 'intel') return 'Intel';
    if (lowerSlug == 'amd') return 'AMD';
    if (lowerSlug == 'nvidia') return 'NVIDIA';
    if (lowerSlug == 'samsung') return 'Samsung';
    if (lowerSlug == 'asus') return 'Asus';
    if (lowerSlug == 'dell') return 'Dell';
    if (lowerSlug == 'lenovo') return 'Lenovo';
    if (lowerSlug == 'acer') return 'Acer';
    if (lowerSlug == 'apple') return 'Apple';
    if (lowerSlug == 'msi') return 'MSI';
    return categoryName;
  }

  /// Icon nhận diện phù hợp theo slug và tên
  IconData get icon {
    final lower = '${slug.toLowerCase()} ${categoryName.toLowerCase()}';
    if (lower.contains('cpu')) return Icons.memory;
    if (lower.contains('main') || lower.contains('bo mạch')) return Icons.developer_board;
    if (lower.contains('ram') || lower.contains('bộ nhớ')) return Icons.storage;
    if (lower.contains('gpu') || lower.contains('vga') || lower.contains('card')) return Icons.videogame_asset;
    if (lower.contains('ssd') || lower.contains('hdd') || lower.contains('ổ cứng') || lower.contains('storage') || lower == 's' || lower.startsWith('s ')) {
      return Icons.save;
    }
    if (lower.contains('psu') || lower.contains('nguồn') || lower.contains('power') || lower == 'n' || lower.startsWith('n ')) return Icons.power;
    if (lower.contains('tản') || lower.contains('cool') || lower.contains('fan') || lower == 't' || lower.startsWith('t ')) return Icons.ac_unit;
    if (lower.contains('case') || lower.contains('vỏ')) return Icons.aspect_ratio;
    if (lower.contains('linh-kien') || lower.contains('linh kien')) return Icons.settings_input_component;
    if (lower.contains('pc-ai') || lower.contains('ai')) return Icons.smart_toy;
    if (lower.contains('pc-gaming') || lower.contains('gaming')) return Icons.sports_esports;
    if (lower.contains('workstation')) return Icons.computer;
    if (lower == 'pc' || lower.contains('desktop') || lower.startsWith('pc ')) return Icons.desktop_windows;
    if (lower.contains('laptop')) return Icons.laptop_chromebook;
    if (lower.contains('hang')) return Icons.verified;
    if (lower.contains('intel') || lower.contains('amd')) return Icons.memory;
    if (lower.contains('nvidia')) return Icons.videogame_asset;
    if (lower.contains('samsung')) return Icons.sd_card;
    if (lower.contains('asus')) return Icons.laptop_mac;
    if (lower.contains('dell')) return Icons.laptop;
    if (lower.contains('apple')) return Icons.apple;
    if (lower.contains('msi')) return Icons.sports_esports;
    if (lower.contains('lenovo') || lower.contains('acer')) return Icons.laptop_chromebook;
    if (lower.contains('màn hình') || lower.contains('monitor')) return Icons.tv;
    if (lower.contains('gear') || lower.contains('phím') || lower.contains('chuột')) return Icons.keyboard;
    return Icons.folder_outlined;
  }

  /// Mã phân loại linh kiện chuẩn để liên kết với Product.componentType
  String? get componentType {
    final lowerSlug = slug.toLowerCase();
    if (lowerSlug == 'cpu') return 'cpu';
    if (lowerSlug == 'main' || lowerSlug == 'mainboard') return 'mainboard';
    if (lowerSlug == 'ram') return 'ram';
    if (lowerSlug == 'gpu' || lowerSlug == 'vga') return 'gpu';
    if (lowerSlug == 'ssd' || lowerSlug == 'storage' || lowerSlug == 's') return 'storage';
    if (lowerSlug == 'psu' || lowerSlug == 'n') return 'psu';
    if (lowerSlug == 'cooler' || lowerSlug == 't') return 'cooler';
    if (lowerSlug == 'case') return 'case';
    if (lowerSlug.contains('laptop')) return 'laptop';
    if (lowerSlug.contains('pc') || lowerSlug.contains('workstation')) return 'pc_prebuilt';
    if (lowerSlug.contains('monitor')) return 'monitor';
    if (lowerSlug.contains('gear')) return 'gear';
    return null;
  }

  /// Trả về tất cả các node lá hoặc toàn bộ cây phẳng
  List<CategoryNode> flatten() {
    final result = <CategoryNode>[this];
    for (final child in children) {
      result.addAll(child.flatten());
    }
    return result;
  }
}
