class ProductCategorySummary {
  final int id;
  final String categoryName;
  final String slug;
  final bool isPrimary;

  const ProductCategorySummary({
    required this.id,
    required this.categoryName,
    required this.slug,
    this.isPrimary = false,
  });

  factory ProductCategorySummary.fromJson(Map<String, dynamic> json) {
    return ProductCategorySummary(
      id: json['id'] as int,
      categoryName: json['categoryName'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryName': categoryName,
        'slug': slug,
        'isPrimary': isPrimary,
      };
}
