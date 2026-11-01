import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/rbac_kpi_card.dart';

/// Organism: Responsive row of KPI cards summarizing roles and permissions metrics.
class RbacKpiRow extends StatelessWidget {
  final List<RoleItem> roles;
  final List<PermissionItem> allPermissions;

  const RbacKpiRow({
    super.key,
    required this.roles,
    required this.allPermissions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final totalRoles = roles.length;
    final systemRoles = roles.where((r) => r.isSystemRole || r.roleName == 'ROLE_NON_LOGIN').length;
    final customRoles = totalRoles - systemRoles;
    final totalPerms = allPermissions.length;

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
            RbacKpiCard(
              title: l10n.totalRoles,
              value: '$totalRoles',
              icon: Icons.admin_panel_settings_outlined,
              color: cs.primary,
              width: cardWidth,
            ),
            RbacKpiCard(
              title: l10n.systemRoles,
              value: '$systemRoles',
              icon: Icons.shield_outlined,
              color: Colors.blue.shade700,
              width: cardWidth,
            ),
            RbacKpiCard(
              title: l10n.customRoles,
              value: '$customRoles',
              icon: Icons.tune_rounded,
              color: Colors.teal.shade700,
              width: cardWidth,
            ),
            RbacKpiCard(
              title: l10n.totalPermissions,
              value: '$totalPerms',
              icon: Icons.key_outlined,
              color: Colors.amber.shade800,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }
}
