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
    return CategoryNode(
      id: json['id'] as int,
      parentId: json['parentId'] as int?,
      categoryName: json['categoryName'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      iconUrl: json['iconUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      children: (json['children'] as List<dynamic>?)
              ?.map((item) => CategoryNode.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
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
