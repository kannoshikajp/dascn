import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';
import '../atoms/user_role_badge.dart';

/// Molecule: Dialog for updating an existing user account profile, role, and active status.
class EditUserDialog extends StatefulWidget {
  final UserSummary user;
  final List<RoleItem> roles;
  final UserManagementService userService;
  final VoidCallback onUserUpdated;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.roles,
    required this.userService,
    required this.onUserUpdated,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late int _selectedRoleId;
  late bool _isActive;
  bool _isSubmitting = false;
  String? _errorMessage;

  late final List<RoleItem> _assignableRoles;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _phoneCtrl = TextEditingController(text: widget.user.phoneNumber ?? '');
    _assignableRoles = widget.roles
        .where((r) => !r.roleName.toUpperCase().contains('NON_LOGIN'))
        .toList();
    _selectedRoleId = _assignableRoles.any((r) => r.id == widget.user.roleId)
        ? widget.user.roleId
        : (_assignableRoles.isNotEmpty ? _assignableRoles.first.id : 1);
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.userService.updateUser(
        id: widget.user.id,
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        avatarUrl: widget.user.avatarUrl,
        roleId: _selectedRoleId,
        isActive: _isActive,
      );

      if (mounted) {
        Navigator.pop(context, true);
        widget.onUserUpdated();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('ApiException: ', '');
          _isSubmitting = false;
        });
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
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(JoppeSpacing.lg),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.editUserTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(width: JoppeSpacing.sm),
                                UserRoleBadge(roleName: widget.user.roleName),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.user.email,
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withAlpha(80),
                        borderRadius: BorderRadius.circular(JoppeShapes.small),
                        border: Border.all(color: cs.error),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: cs.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: cs.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: JoppeSpacing.md),
                  ],

                  // Full Name
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.fullName,
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.nameRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: JoppeSpacing.md),

                  // Phone
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: JoppeSpacing.md),

                  // Role
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedRoleId,
                    decoration: InputDecoration(
                      labelText: l10n.role,
                      prefixIcon: const Icon(Icons.shield_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                    ),
                    items: _assignableRoles.map((r) {
                      return DropdownMenuItem<int>(
                        value: r.id,
                        child: Text('${l10n.userRoleLabel(r.roleName)} (${r.roleName})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRoleId = val);
                    },
                  ),
                  const SizedBox(height: JoppeSpacing.md),

                  // Active Switch
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                      borderRadius: BorderRadius.circular(JoppeShapes.small),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        l10n.accountActive,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        _isActive ? l10n.activeStatus : l10n.suspendedStatus,
                        style: TextStyle(
                          color: _isActive ? Colors.green.shade700 : cs.error,
                          fontSize: 12,
                        ),
                      ),
                      value: _isActive,
                      activeThumbColor: Colors.green.shade700,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ),
                  const SizedBox(height: JoppeSpacing.lg),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: JoppeSpacing.sm),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(l10n.saveChanges),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
