/// Model đại diện cho các khối danh mục sản phẩm lớn viền xanh Cyber
class CategoryShowcaseItem {
  final String id;
  final String title;
  final String subtitle;
  final String slug;
  final String iconName;
  final int itemCount;

  const CategoryShowcaseItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.slug,
    this.iconName = '',
    this.itemCount = 0,
  });
}
