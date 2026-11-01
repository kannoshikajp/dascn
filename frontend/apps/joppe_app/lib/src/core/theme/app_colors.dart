import 'package:flutter/material.dart';

/// Bảng màu chuẩn thiết kế Warm Human Minimalism cho Joppe Mobile (iOS & Android)
/// Trích xuất từ Design DNA: Tông màu cam đất (Warm Terracotta #DE6E39), nền vải ấm (#F6F5F5), chữ than chì (#242424)
class AppColors {
  // Bảng màu thương hiệu & Hành động (Warm Terracotta Editorial Theme)
  static const Color primaryBlue = Color(0xFFDE6E39);       // Terracotta Cam đất ấm - Nút bấm, điểm nhấn chính, CTA
  static const Color neonCyan = Color(0xFFDE6E39);          // Warm Accent - Tab active, viền highlight
  static const Color warmTan = Color(0xFFD5B08B);           // Warm Amber/Tan - Huy hiệu nhẹ, secondary highlight
  static const Color accentRed = Color(0xFFD32F2F);         // Đỏ tươi - Huy hiệu sale, giỏ hàng, xóa

  // Nền & Khối bề mặt (Warm Linen & Pure Card Canvas)
  static const Color navyBackground = Color(0xFFF6F5F5);    // Linen 50 - Nền canvas tổng thể ấm dịu mắt
  static const Color surfaceCard = Color(0xFFFFFFFF);       // Trắng tinh khiết - Thẻ sản phẩm, panel
  static const Color surfaceCardLighter = Color(0xFFFDF6F2);// Warm Peach Tint - Thẻ active / hover / highlight
  static const Color surfaceSubtle = Color(0xFFEFEFED);     // Nền tab con, pill chưa active
  static const Color primaryDark = Color(0xFFFFFFFF);       // Trắng tinh - Header, AppBar, thanh điều hướng
  static const Color searchFieldBg = Color(0xFFEFEFED);     // Warm Grey 100 - Nền ô tìm kiếm, ô nhập liệu

  // Đường viền & Phân tách (Soft 1px Borders)
  static const Color borderLight = Color(0xFFE8E6E5);       // Viền mờ 1px mềm mại
  static const Color borderAccent = Color(0xFFDE6E39);      // Cam đất - Viền khi active / focus

  // Trạng thái & Đo lường (Status & Gauges)
  static const Color shimmerBase = Color(0xFFEFEFED);       // Nền Shimmer tải trang
  static const Color shimmerHighlight = Color(0xFFF6F5F5);  // Vệt sáng Shimmer
  static const Color wattageSafe = Color(0xFF2E7D32);       // Xanh lá chuẩn Clean UI
  static const Color wattageWarning = Color(0xFFDE6E39);    // Cam đất
  static const Color wattageDanger = Color(0xFFD32F2F);     // Đỏ cảnh báo

  // Chữ & Biểu tượng (Typography & Icons)
  static const Color textPrimary = Color(0xFF242424);       // Charcoal Than chì sâu - Chữ tiêu đề, nội dung chính
  static const Color textMuted = Color(0xFF5B554F);         // Warm Grey 600 - Chữ phụ, mô tả, thông số kỹ thuật
  static const Color textSubtle = Color(0xFF8C857F);        // Warm Grey 500 - Gợi ý, nhãn mờ
  static const Color textWhite = Color(0xFF242424);         // Tương thích ngược: map sang Than chì cho nền sáng
  static const Color textOnAction = Color(0xFFFFFFFF);      // Trắng tinh - Dành cho chữ trên nút bấm cam/đỏ
}
