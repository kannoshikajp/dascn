import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Atom: Avatar người dùng bo tròn mềm mại
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final double iconSize;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.size = 64,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryBlue.withValues(alpha: 0.1),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.25),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
            ? Image.network(
                avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(Icons.person_rounded, color: AppColors.primaryBlue, size: iconSize),
                ),
              )
            : Center(
                child: Icon(Icons.person_rounded, color: AppColors.primaryBlue, size: iconSize),
              ),
      ),
    );
  }
}
