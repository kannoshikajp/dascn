import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import '../../../localization/dashboard_localizations.dart';

/// Atom: Three-dot dropdown menu providing row-level actions for user accounts.
class UserActionMenu extends StatelessWidget {
  final UserSummary user;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const UserActionMenu({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 20),
      tooltip: l10n.actionCol,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (action) {
        switch (action) {
          case 'edit':
            onEdit();
            break;
          case 'toggle_status':
            onToggleStatus();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(l10n.editUser),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle_status',
          child: Row(
            children: [
              Icon(
                user.isActive ? Icons.block_rounded : Icons.check_circle_outline,
                size: 18,
                color: user.isActive ? cs.error : Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(user.isActive ? l10n.suspendUser : l10n.activateUser),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: cs.error),
              const SizedBox(width: 8),
              Text(l10n.deleteUser, style: TextStyle(color: cs.error)),
            ],
          ),
        ),
      ],
    );
  }
}
