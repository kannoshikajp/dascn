class CategoryItem {
  final int id;
  final int? parentId;
  final String? parentName;
  final String categoryName;
  final String slug;
  final String? iconUrl;
  final bool isActive;
  final DateTime? createdAt;
  final int productCount;
  final int childCount;

  const CategoryItem({
    required this.id,
    this.parentId,
    this.parentName,
    required this.categoryName,
    required this.slug,
    this.iconUrl,
    this.isActive = true,
    this.createdAt,
    this.productCount = 0,
    this.childCount = 0,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as int,
      parentId: json['parentId'] as int?,
      parentName: json['parentName'] as String?,
      categoryName: json['categoryName'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      iconUrl: json['iconUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      childCount: (json['childCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentId': parentId,
        'parentName': parentName,
        'categoryName': categoryName,
        'slug': slug,
        'iconUrl': iconUrl,
        'isActive': isActive,
        'createdAt': createdAt?.toIso8601String(),
        'productCount': productCount,
        'childCount': childCount,
      };
}
