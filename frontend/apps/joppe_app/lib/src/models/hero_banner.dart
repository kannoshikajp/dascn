/// Model đại diện cho Banner quảng cáo chính (Hero Promo Banner)
class HeroBannerItem {
  final String id;
  final String tag;
  final String title;
  final String subtitle;
  final List<String> specs;
  final String imageUrl;
  final String actionLabel;
  final String route;

  const HeroBannerItem({
    required this.id,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.specs,
    required this.imageUrl,
    this.actionLabel = 'KHÁM PHÁ NGAY',
    this.route = '',
  });
}
