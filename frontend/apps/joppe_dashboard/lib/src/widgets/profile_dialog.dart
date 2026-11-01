import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import 'image_upload_field.dart';

class ProfileDialog extends StatefulWidget {
  final UserProfile profile;
  final AuthService authService;
  final MediaUploadService? mediaService;
  final ValueChanged<UserProfile>? onProfileUpdated;

  const ProfileDialog({
    super.key,
    required this.profile,
    required this.authService,
    this.mediaService,
    this.onProfileUpdated,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _avatarUrlController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phoneNumber ?? '');
    _avatarUrlController = TextEditingController(text: widget.profile.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _avatarUrlController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    const defaultApiUrl = 'http://localhost:8080';
    if (url.startsWith('/')) {
      return '$defaultApiUrl$url';
    }
    return '$defaultApiUrl/$url';
  }

  Future<void> _handleSaveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);

    try {
      final updated = await widget.authService.updateProfile(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim().isEmpty ? null : _avatarUrlController.text.trim(),
      );

      widget.onProfileUpdated?.call(updated);

      if (mounted) {
        setState(() => _isSavingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleChangePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isChangingPassword = true);

    try {
      await widget.authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        setState(() => _isChangingPassword = false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChangingPassword = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change password: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarUrl = _avatarUrlController.text.trim();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with user summary
            Container(
              padding: const EdgeInsets.all(JoppeSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(_resolveImageUrl(avatarUrl))
                        : null,
                    onBackgroundImageError: avatarUrl.isNotEmpty ? (_, _) {} : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            widget.profile.fullName.isNotEmpty
                                ? widget.profile.fullName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: JoppeSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.profile.fullName.isNotEmpty
                              ? widget.profile.fullName
                              : 'Account Profile',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.profile.email,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.person_outline), text: 'Profile Details'),
                Tab(icon: Icon(Icons.lock_outline), text: 'Security'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Profile Details
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(JoppeSpacing.md),
                    child: Form(
                      key: _profileFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Avatar field with upload
                          ImageUploadField(
                            controller: _avatarUrlController,
                            mediaUploadService: widget.mediaService,
                            folder: 'avatars',
                            label: 'Avatar Image',
                            hint: 'Image URL or pick file to upload avatar',
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: JoppeSpacing.md),

                          // Full Name
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name *',
                              prefixIcon: Icon(Icons.badge_outlined, size: 20),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              if (val.trim().length > 150) {
                                return 'Full name cannot exceed 150 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: JoppeSpacing.md),

                          // Phone Number
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined, size: 20),
                              hintText: 'e.g. 0912345678',
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              if (val != null && val.trim().length > 20) {
                                return 'Phone number cannot exceed 20 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: JoppeSpacing.md),

                          // Email (Read-only)
                          TextFormField(
                            initialValue: widget.profile.email,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Email Address (Account Identifier)',
                              prefixIcon: const Icon(Icons.email_outlined, size: 20),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              helperText: 'Email address cannot be changed directly.',
                            ),
                          ),
                          const SizedBox(height: JoppeSpacing.lg),

                          // Save Profile button
                          FilledButton.icon(
                            onPressed: _isSavingProfile ? null : _handleSaveProfile,
                            icon: _isSavingProfile
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.check, size: 18),
                            label: Text(_isSavingProfile ? 'Saving...' : 'Save Profile'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab 2: Security / Password
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(JoppeSpacing.md),
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Change Account Password',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ensure your new password has at least 6 characters.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: JoppeSpacing.md),

                          // Current Password
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrent,
                            decoration: InputDecoration(
                              labelText: 'Current Password *',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureCurrent = !_obscureCurrent),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Current password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: JoppeSpacing.md),

                          // New Password
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: _obscureNew,
                            decoration: InputDecoration(
                              labelText: 'New Password *',
                              prefixIcon: const Icon(Icons.lock_reset, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNew ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureNew = !_obscureNew),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'New password is required';
                              }
                              if (val.length < 6) {
                                return 'New password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: JoppeSpacing.md),

                          // Confirm New Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password *',
                              prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your new password';
                              }
                              if (val != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: JoppeSpacing.lg),

                          // Change Password button
                          FilledButton.icon(
                            onPressed: _isChangingPassword ? null : _handleChangePassword,
                            icon: _isChangingPassword
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.security, size: 18),
                            label: Text(_isChangingPassword
                                ? 'Updating Password...'
                                : 'Update Password'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
