/// Model thông tin sản phẩm công nghệ hoàn chỉnh (Hardware, PC, Laptop, Gear)
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final String category;
  final String brand;
  final int warrantyMonths;
  final List<String> specs;
  final bool isFeatured;
  final bool inStock;

  /// Mã loại linh kiện cho tính năng lọc và Build PC: 'cpu', 'gpu', 'mainboard', 'ram', 'storage', 'psu', 'cooler', 'case', 'laptop', 'monitor', 'gear', 'pc_prebuilt'
  final String? componentType;

  /// Thông số kỹ thuật chi tiết dạng bảng (key-value)
  final Map<String, String> technicalSpecs;

  /// Danh sách URL Slugs của danh mục (ví dụ: ['asus', 'laptop-gaming'])
  final List<String> categorySlugs;

  /// Danh sách ID danh mục từ API
  final List<int> categoryIds;

  /// Danh sách tên danh mục trực tiếp từ API (ví dụ: ['Asus', 'Gaming', 'Laptop'])
  final List<String> categoryNames;

  /// Đánh giá từ người dùng (1.0 đến 5.0)
  final double rating;

  /// Số lượng lượt đánh giá
  final int reviewCount;

  /// Mã phiên bản phần cứng gia đình (theo API_SCHEMA.md mục 7)
  final String? versionCode;

  /// Mã biến thể phần cứng (theo API_SCHEMA.md mục 7)
  final String? variantCode;

  /// Composite slug cho deep linking: ${product.slug}-${variant.variantCode}
  final String? compositeSlug;

  /// Mã định danh biến thể phần cứng trực tiếp từ API (dùng cho Cart & Order Checkout)
  final String? variantId;

  /// Album ảnh chi tiết của sản phẩm / biến thể
  final List<String> albumUrls;

  const Product({
    required this.id,
    this.variantId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.originalPrice,
    this.category = 'PC Gaming',
    this.brand = 'Gigabyte',
    this.warrantyMonths = 36,
    this.specs = const [],
    this.isFeatured = false,
    this.inStock = true,
    this.componentType,
    this.technicalSpecs = const {},
    this.categorySlugs = const [],
    this.categoryIds = const [],
    this.categoryNames = const [],
    this.rating = 4.8,
    this.reviewCount = 0,
    this.versionCode,
    this.variantCode,
    this.compositeSlug,
    this.albumUrls = const [],
  });

  /// Tạo bản sao với các thuộc tính cập nhật
  Product copyWith({
    String? id,
    String? variantId,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? imageUrl,
    String? category,
    String? brand,
    int? warrantyMonths,
    List<String>? specs,
    bool? isFeatured,
    bool? inStock,
    String? componentType,
    Map<String, String>? technicalSpecs,
    List<String>? categorySlugs,
    List<int>? categoryIds,
    List<String>? categoryNames,
    double? rating,
    int? reviewCount,
    String? versionCode,
    String? variantCode,
    String? compositeSlug,
    List<String>? albumUrls,
  }) {
    return Product(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      specs: specs ?? this.specs,
      isFeatured: isFeatured ?? this.isFeatured,
      inStock: inStock ?? this.inStock,
      componentType: componentType ?? this.componentType,
      technicalSpecs: technicalSpecs ?? this.technicalSpecs,
      categorySlugs: categorySlugs ?? this.categorySlugs,
      categoryIds: categoryIds ?? this.categoryIds,
      categoryNames: categoryNames ?? this.categoryNames,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      versionCode: versionCode ?? this.versionCode,
      variantCode: variantCode ?? this.variantCode,
      compositeSlug: compositeSlug ?? this.compositeSlug,
      albumUrls: albumUrls ?? this.albumUrls,
    );
  }

  /// Tỷ giá quy đổi tham chiếu VND (mặc định 1.0 cho tiền tệ VND nội địa)
  static const double usdToVndRate = 1.0;

  /// Định dạng số tiền VND theo chuẩn (ví dụ: 13990000 -> "13.990.000 ₫", 0 -> "0 ₫")
  static String formatVnd(double amount) {
    if (amount.isNaN || amount.isInfinite) return '0 ₫';
    final rounded = amount.round();
    final isNegative = rounded < 0;
    final absStr = rounded.abs().toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = absStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return '${isNegative ? '-' : ''}$formatted ₫';
  }

  /// Tính phần trăm giảm giá nếu có giá gốc hợp lệ
  int get discountPercentage {
    if (originalPrice == null || originalPrice! <= price || originalPrice! <= 0) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  /// Chuỗi hiển thị giá bán VND chính thức (ví dụ: "13.990.000 ₫")
  String get formattedPrice => formatVnd(price);

  /// Chuỗi hiển thị giá gốc VND (ví dụ: "16.120.000 ₫")
  String get formattedOriginalPrice =>
      originalPrice != null ? formatVnd(originalPrice!) : '';

  /// Getter hỗ trợ tương thích ngược cho VND
  double get priceVnd => price;
  double? get originalPriceVnd => originalPrice;
  String get formattedPriceVnd => formattedPrice;
  String get formattedOriginalPriceVnd => formattedOriginalPrice;

  /// Tương thích ngược: chuyển hướng hiển thị sang VND
  String get formattedPriceUsd => formattedPrice;
  String get formattedOriginalPriceUsd => formattedOriginalPrice;
}
