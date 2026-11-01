import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Molecule: Confirmation dialog for permanently deleting a user account.
class DeleteUserDialog extends StatefulWidget {
  final UserSummary user;
  final UserManagementService userService;
  final VoidCallback onUserDeleted;

  const DeleteUserDialog({
    super.key,
    required this.user,
    required this.userService,
    required this.onUserDeleted,
  });

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  bool _isDeleting = false;
  String? _errorMessage;

  Future<void> _delete() async {
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await widget.userService.deleteUser(widget.user.id);
      if (mounted) {
        Navigator.pop(context, true);
        widget.onUserDeleted();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('ApiException: ', '');
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(JoppeShapes.large)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.errorContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(JoppeShapes.small),
            ),
            child: Icon(Icons.delete_forever_rounded, color: cs.error, size: 20),
          ),
          const SizedBox(width: JoppeSpacing.sm),
          Text(
            l10n.deleteUserConfirmTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deleteUserConfirmPrompt(widget.user.fullName, widget.user.email),
              style: const TextStyle(fontSize: 14),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: JoppeSpacing.sm),
              Text(_errorMessage!, style: TextStyle(color: cs.error, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: cs.error),
          onPressed: _isDeleting ? null : _delete,
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.deleteUser),
        ),
      ],
    );
  }
}
