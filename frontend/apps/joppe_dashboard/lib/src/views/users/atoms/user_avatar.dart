import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

/// Atom: User avatar component with fallback to role-tinted initials.
class UserAvatar extends StatelessWidget {
  final UserSummary user;
  final double radius;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 18,
  });

  Color _getRoleColor(BuildContext context, String roleName) {
    final cs = Theme.of(context).colorScheme;
    final r = roleName.toUpperCase();
    if (r.contains('ADMIN')) return cs.primary;
    if (r.contains('STAFF')) return Colors.teal.shade700;
    return cs.onSurfaceVariant;
  }

  Color _getRoleBgColor(BuildContext context, String roleName) {
    final cs = Theme.of(context).colorScheme;
    final r = roleName.toUpperCase();
    if (r.contains('ADMIN')) return cs.primaryContainer;
    if (r.contains('STAFF')) return Colors.teal.shade100;
    return cs.surfaceContainerHighest;
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    final initial = user.fullName.trim().isNotEmpty
        ? user.fullName.trim().substring(0, 1).toUpperCase()
        : (user.email.isNotEmpty ? user.email.substring(0, 1).toUpperCase() : 'U');

    final bgColor = _getRoleBgColor(context, user.roleName);
    final fgColor = _getRoleColor(context, user.roleName);

    if (hasAvatar) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: NetworkImage(user.avatarUrl!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initial,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
