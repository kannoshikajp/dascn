import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/user_kpi_card.dart';

/// Organism: Responsive row of KPI cards summarizing user account metrics.
class UserKpiRow extends StatelessWidget {
  final List<UserSummary> users;

  const UserKpiRow({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final totalUsers = users.length;
    final activeUsers = users.where((u) => u.isActive).length;
    final suspendedUsers = users.where((u) => !u.isActive).length;
    final staffAndAdmin = users.where((u) {
      final r = u.roleName.toUpperCase();
      return r.contains('ADMIN') || r.contains('STAFF');
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final cardWidth = isCompact
            ? (constraints.maxWidth - JoppeSpacing.md) / 2
            : (constraints.maxWidth - (JoppeSpacing.md * 3)) / 4;

        return Wrap(
          spacing: JoppeSpacing.md,
          runSpacing: JoppeSpacing.md,
          children: [
            UserKpiCard(
              title: l10n.totalUsersKpi,
              value: '$totalUsers',
              icon: Icons.people_outline_rounded,
              color: cs.primary,
              width: cardWidth,
            ),
            UserKpiCard(
              title: l10n.activeUsersKpi,
              value: '$activeUsers',
              icon: Icons.check_circle_outline_rounded,
              color: Colors.green.shade700,
              width: cardWidth,
            ),
            UserKpiCard(
              title: l10n.suspendedUsersKpi,
              value: '$suspendedUsers',
              icon: Icons.block_outlined,
              color: cs.error,
              width: cardWidth,
            ),
            UserKpiCard(
              title: l10n.staffAndAdminKpi,
              value: '$staffAndAdmin',
              icon: Icons.admin_panel_settings_outlined,
              color: Colors.purple.shade700,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }
}
