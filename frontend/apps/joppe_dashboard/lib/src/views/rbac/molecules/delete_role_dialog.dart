import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Molecule: Safety confirmation dialog before deleting a custom role.
class DeleteRoleDialog extends StatefulWidget {
  final RoleItem role;
  final RbacManagementService rbacService;
  final VoidCallback onRoleDeleted;
  final void Function(String message, {bool isError}) notify;

  const DeleteRoleDialog({
    super.key,
    required this.role,
    required this.rbacService,
    required this.onRoleDeleted,
    required this.notify,
  });

  @override
  State<DeleteRoleDialog> createState() => _DeleteRoleDialogState();
}

class _DeleteRoleDialogState extends State<DeleteRoleDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    final l10n = context.l10n;

    try {
      await widget.rbacService.deleteRole(widget.role.id);
      if (mounted) {
        Navigator.pop(context);
        widget.notify(l10n.roleDeletedSuccess, isError: false);
        widget.onRoleDeleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        widget.notify(
          e.toString().replaceFirst('ApiException: ', ''),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(JoppeShapes.large)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.errorContainer.withAlpha(90),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded, color: cs.error, size: 28),
              ),
              const SizedBox(height: JoppeSpacing.md),
              Text(
                l10n.deleteRole,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: JoppeSpacing.sm),
              Text(
                l10n.deleteRoleConfirm(widget.role.roleName),
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: JoppeSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isDeleting ? null : () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: JoppeSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isDeleting ? null : _handleDelete,
                      style: FilledButton.styleFrom(backgroundColor: cs.error),
                      child: _isDeleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l10n.deleteRole),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
