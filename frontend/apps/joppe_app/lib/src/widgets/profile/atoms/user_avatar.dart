import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
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
    final resolvedUrl = ApiClient.resolveUrl(avatarUrl);
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
        child: resolvedUrl.isNotEmpty
            ? Image.network(
                resolvedUrl,
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
