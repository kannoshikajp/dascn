import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../../../localization/dashboard_localizations.dart';

/// Molecule: Dialog for creating a new user account with role assignment.
class CreateUserDialog extends StatefulWidget {
  final UserManagementService userService;
  final List<RoleItem> roles;
  final VoidCallback onUserCreated;

  const CreateUserDialog({
    super.key,
    required this.userService,
    required this.roles,
    required this.onUserCreated,
  });

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  late int _selectedRoleId;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  late final List<RoleItem> _assignableRoles;

  @override
  void initState() {
    super.initState();
    _assignableRoles = widget.roles
        .where((r) => !r.roleName.toUpperCase().contains('NON_LOGIN'))
        .toList();
    _selectedRoleId = _assignableRoles.isNotEmpty ? _assignableRoles.first.id : 1;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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
      await widget.userService.createUser(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        roleId: _selectedRoleId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        widget.onUserCreated();
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
                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(JoppeShapes.small),
                            ),
                            child: Icon(Icons.person_add_alt_1_rounded, color: cs.primary, size: 22),
                          ),
                          const SizedBox(width: JoppeSpacing.sm),
                          Text(
                            l10n.addUser,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
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

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty || !v.contains('@')) {
                        return l10n.emailRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: JoppeSpacing.md),

                  // Password
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(JoppeShapes.small)),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return l10n.passwordMinLengthRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: JoppeSpacing.md),

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
                  const SizedBox(height: JoppeSpacing.lg),

                  // Actions
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
                            : const Icon(Icons.person_add, size: 18),
                        label: Text(l10n.addUser),
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
