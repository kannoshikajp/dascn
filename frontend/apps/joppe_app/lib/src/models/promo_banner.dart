/// Model đại diện cho các banner khuyến mãi sự kiện nhỏ (Mini Promo Banners)
class MiniPromoBanner {
  final String id;
  final String title;
  final String subtitle;
  final String? badge;
  final String themeType; // 'school' | 'sale' | 'deal'
  final String imageUrl;
  final String route;

  const MiniPromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    this.badge,
    this.themeType = 'sale',
    this.imageUrl = '',
    this.route = '',
  });
}
