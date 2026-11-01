import 'package:flutter/material.dart';
import '../models/category_showcase.dart';
import '../models/hero_banner.dart';
import '../models/promo_banner.dart';
import '../models/quick_action.dart';

/// Dữ liệu mẫu hoàn chỉnh cho trang chủ Joppe E-Commerce
class HomeMockData {
  // 1. Dữ liệu Banner quảng cáo chính (Hero Promo Banners)
  static const List<HeroBannerItem> heroBanners = [
    HeroBannerItem(
      id: 'hero-gigabyte-z890',
      tag: 'PC AI GIGABYTE',
      title: 'PC AI GIGABYTE AI TOP 100 Z890',
      subtitle: 'DẪN ĐẦU HIỆU NĂNG AI',
      specs: [
        '36GB VRAM GDDR6X - 18GHz 4460 TOPS AI',
        'Mainboard Z890 AORUS MASTER AI TOP',
        'Intel Core Ultra 9 285K / 64GB DDR5 6400MHz',
        '350K RDB 1800 MHz dẫn đầu chỉ số hiệu năng',
      ],
      imageUrl: 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?auto=format&fit=crop&w=1000&q=80',
      actionLabel: 'KHÁM PHÁ CẤU HÌNH',
      route: '/product/pc-ai-gigabyte-z890',
    ),
    HeroBannerItem(
      id: 'hero-rtx-5080',
      tag: 'THẾ HỆ MỚI',
      title: 'GEFORCE RTX 5080 SERIES',
      subtitle: 'ĐỈNH CAO ĐỒ HỌA RAY TRACING',
      specs: [
        'Kiến trúc Blackwell 4nm đột phá',
        'DLSS 4.0 Neural Rendering thế hệ mới',
        '16GB GDDR7 28Gbps băng thông cực đại',
        'Tản nhiệt buồng hơi Tri-Frozr 3S',
      ],
      imageUrl: 'https://images.unsplash.com/photo-1591488320449-011701bb6704?auto=format&fit=crop&w=1000&q=80',
      actionLabel: 'ĐẶT TRƯỚC NGAY',
      route: '/product/rtx-5080',
    ),
  ];

  // 2. Dữ liệu 8 nút tiện ích vuông (Quick Action Tiles)
  static const List<QuickActionItem> quickActions = [
    QuickActionItem(
      id: 'qa-ai-support',
      title: 'Hỗ trợ AI',
      icon: Icons.psychology_outlined,
      badgeText: 'HOT',
      route: '/ai-support',
    ),
    QuickActionItem(
      id: 'qa-build-pc',
      title: 'Build PC',
      icon: Icons.computer_outlined,
      route: '/build-pc',
    ),
    QuickActionItem(
      id: 'qa-promotions',
      title: 'Khuyến Mãi',
      icon: Icons.percent_outlined,
      badgeText: 'SALE',
      route: '/promotions',
    ),
    QuickActionItem(
      id: 'qa-compare',
      title: 'So Sánh',
      icon: Icons.balance_outlined,
      route: '/compare',
    ),
    QuickActionItem(
      id: 'qa-calculator',
      title: 'Tự tính',
      icon: Icons.calculate_outlined,
      route: '/pc-calculator',
    ),
    QuickActionItem(
      id: 'qa-chat',
      title: 'Chat',
      icon: Icons.chat_bubble_outline,
      route: '/chat',
    ),
    QuickActionItem(
      id: 'qa-zalo',
      title: 'Zalo',
      icon: Icons.forum_outlined,
      isExternal: true,
      route: 'https://zalo.me',
    ),
    QuickActionItem(
      id: 'qa-hotline',
      title: 'Hotline',
      icon: Icons.phone_in_talk_outlined,
      isExternal: true,
      route: 'tel:0868302123',
    ),
  ];

  // 3. Dữ liệu hàng 5 Banner sự kiện nhỏ (Mini Promo Banners)
  static const List<MiniPromoBanner> miniPromos = [
    MiniPromoBanner(
      id: 'mini-1',
      title: 'Back to School',
      subtitle: 'Giảm tới 40%',
      themeType: 'school',
      badge: '-40%',
    ),
    MiniPromoBanner(
      id: 'mini-2',
      title: '9/9 Promo',
      subtitle: 'Siêu Sale PC',
      themeType: 'sale',
      badge: 'HOT DEAL',
    ),
    MiniPromoBanner(
      id: 'mini-3',
      title: 'Back to School',
      subtitle: 'Tặng Gear Gaming',
      themeType: 'school',
      badge: 'QUÀ TẶNG',
    ),
    MiniPromoBanner(
      id: 'mini-4',
      title: 'Back to Promo',
      subtitle: 'Flash Deal 24H',
      themeType: 'sale',
      badge: '24H',
    ),
    MiniPromoBanner(
      id: 'mini-5',
      title: 'Back to School',
      subtitle: 'Voucher Sinh viên',
      themeType: 'school',
      badge: 'CODE 500K',
    ),
  ];

  // 4. Dữ liệu các khối danh mục lớn viền Cyber (Category Showcase Boxes)
  static const List<CategoryShowcaseItem> categoryShowcases = [
    CategoryShowcaseItem(
      id: 'cat-components',
      title: 'LINH KIỆN BUILD PC',
      subtitle: 'CPU, Mainboard, RAM, SSD, Nguồn PSU, Tản nhiệt',
      slug: 'linh-kien-pc',
      itemCount: 156,
    ),
    CategoryShowcaseItem(
      id: 'cat-laptop',
      title: 'LAPTOP GAMING',
      subtitle: 'RTX 40 Series / Core i7-i9 / Ryzen 7-9',
      slug: 'laptop-gaming',
      itemCount: 48,
    ),
    CategoryShowcaseItem(
      id: 'cat-monitor',
      title: 'MÀN HÌNH GAMING',
      subtitle: '144Hz - 360Hz / 2K - 4K OLED',
      slug: 'man-hinh-gaming',
      itemCount: 65,
    ),
    CategoryShowcaseItem(
      id: 'cat-gear',
      title: 'GEAR GAMING',
      subtitle: 'Bàn phím cơ, Chuột Wireless, Tai nghe 7.1',
      slug: 'gear-gaming',
      itemCount: 120,
    ),
    CategoryShowcaseItem(
      id: 'cat-workstation',
      title: 'PC ĐỒ HỌA',
      subtitle: 'Render 3D, Premiere, AI Training Station',
      slug: 'pc-do-hoa',
      itemCount: 32,
    ),
  ];
}
