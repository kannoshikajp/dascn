import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// Hiệu ứng Shimmer quét vệt sáng công nghệ Cyberpunk cho các trạng thái tải trang (Skeleton Loading)
class CyberShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final BoxBorder? border;
  final Widget? child;

  const CyberShimmer({
    super.key,
    this.width,
    this.height,
    this.border,
    this.child,
  });

  @override
  State<CyberShimmer> createState() => _CyberShimmerState();
}

class _CyberShimmerState extends State<CyberShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: widget.border ?? Border.all(color: AppColors.borderLight, width: 1),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (val * 3), -0.5),
              end: Alignment(0.5 + (val * 3), 0.5),
              colors: const [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                Color(0x220EA5E9), // Thoảng nhẹ ánh Sky Blue
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Widget bọc hiệu ứng nhấn xúc giác cơ học (Mechanical Switch Tactile Press)
/// Tạo cảm giác bấm nảy cơ học (Tactile Feedback) chuẩn 90 độ cho các nút bấm & thẻ sản phẩm
class TactilePress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final bool enableHaptic;
  final HitTestBehavior behavior;

  const TactilePress({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.965,
    this.enableHaptic = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<TactilePress> createState() => _TactilePressState();
}

class _TactilePressState extends State<TactilePress> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null) return;
    _controller.forward();
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
