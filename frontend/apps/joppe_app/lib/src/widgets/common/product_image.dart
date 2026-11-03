import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import '../../core/theme/app_colors.dart';
import 'cyber_effects.dart';

/// Widget hiển thị hình ảnh sản phẩm công nghệ có cơ chế tải và xử lý ngoại lệ mạng thông minh
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final String? componentType;
  final String? brand;
  final BoxFit fit;
  final double? width;
  final double? height;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.componentType,
    this.brand,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  IconData _getFallbackIcon() {
    switch (componentType?.toLowerCase()) {
      case 'cpu':
        return Icons.memory;
      case 'mainboard':
        return Icons.developer_board;
      case 'ram':
        return Icons.storage;
      case 'gpu':
      case 'vga':
        return Icons.videogame_asset;
      case 'storage':
      case 'ssd':
        return Icons.save;
      case 'psu':
        return Icons.power;
      case 'cooler':
        return Icons.ac_unit;
      case 'case':
        return Icons.aspect_ratio;
      case 'laptop':
        return Icons.laptop_chromebook;
      case 'monitor':
        return Icons.tv;
      case 'gear':
        return Icons.sports_esports;
      case 'pc_prebuilt':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiClient.resolveUrl(imageUrl);
    if (resolvedUrl.trim().isEmpty) {
      return _buildPlaceholder();
    }

    return Image.network(
      resolvedUrl,
      fit: fit,
      width: width,
      height: height,
      headers: kIsWeb
          ? null
          : const {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return CyberShimmer(
          width: width,
          height: height,
          child: const Center(
            child: Icon(Icons.memory, color: AppColors.neonCyan, size: 20),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    final icon = _getFallbackIcon();
    final brandText = (brand ?? componentType ?? 'JOPPE').toUpperCase();
    final isCompact = height != null && height! < 65;

    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceCardLighter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cyber subtle diagonal grid & brackets
          Positioned.fill(
            child: CustomPaint(
              painter: _CyberGridPainter(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isCompact ? 20 : (height != null && height! < 100 ? 24 : 36),
                color: AppColors.neonCyan.withValues(alpha: 0.8),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppColors.surfaceCard,
                  child: Text(
                    brandText,
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.35)
      ..strokeWidth = 1.5;

    // Corner brackets 90 độ
    const b = 10.0;
    // Top-left
    canvas.drawLine(Offset.zero, const Offset(b, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, b), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - b, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - b), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
