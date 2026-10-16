import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../views/overview_view.dart';
import '../views/users_view.dart';
import '../views/rbac_view.dart';
import '../views/categories_view.dart';
import '../views/products_view.dart';
import '../widgets/profile_dialog.dart';

class DashboardShell extends StatefulWidget {
  final AuthSession session;
  final AuthService authService;
  final UserManagementService userService;
  final RbacManagementService rbacService;
  final CategoryManagementService categoryService;
  final ProductManagementService productService;
  final MediaUploadService? mediaService;
  final VoidCallback onLogout;

  const DashboardShell({
    super.key,
    required this.session,
    required this.authService,
    required this.userService,
    required this.rbacService,
    required this.categoryService,
    required this.productService,
    this.mediaService,
    required this.onLogout,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _profile = UserProfile(
      id: widget.session.userId,
      email: widget.session.email,
      fullName: widget.session.fullName,
      role: widget.session.role,
      permissions: widget.session.permissions,
    );
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await widget.authService.getCurrentProfile();
      if (mounted) {
        setState(() => _profile = p);
      }
    } catch (_) {
      // Keep session fallback if offline or failed
    }
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

  Future<void> _openProfileDialog() async {
    final current = _profile ??
        UserProfile(
          id: widget.session.userId,
          email: widget.session.email,
          fullName: widget.session.fullName,
          role: widget.session.role,
          permissions: widget.session.permissions,
        );

    await showDialog(
      context: context,
      builder: (ctx) => ProfileDialog(
        profile: current,
        authService: widget.authService,
        mediaService: widget.mediaService,
        onProfileUpdated: (updated) {
          setState(() => _profile = updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final destinations = const [
      JoppeNavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Overview',
      ),
      JoppeNavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Users',
      ),
      JoppeNavigationDestination(
        icon: Icon(Icons.category_outlined),
        selectedIcon: Icon(Icons.category),
        label: 'Categories',
      ),
      JoppeNavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Products',
      ),
      JoppeNavigationDestination(
        icon: Icon(Icons.shield_outlined),
        selectedIcon: Icon(Icons.shield),
        label: 'RBAC Matrix',
      ),
    ];

    Widget currentBody;
    switch (_selectedIndex) {
      case 0:
        currentBody = OverviewView(
          userService: widget.userService,
          rbacService: widget.rbacService,
          categoryService: widget.categoryService,
          productService: widget.productService,
          onNavigateToUsers: () => setState(() => _selectedIndex = 1),
          onNavigateToCategories: () => setState(() => _selectedIndex = 2),
          onNavigateToProducts: () => setState(() => _selectedIndex = 3),
          onNavigateToRbac: () => setState(() => _selectedIndex = 4),
        );
        break;
      case 1:
        currentBody = UsersView(
          userService: widget.userService,
          rbacService: widget.rbacService,
        );
        break;
      case 2:
        currentBody = CategoriesView(
          categoryService: widget.categoryService,
          mediaUploadService: widget.mediaService,
        );
        break;
      case 3:
        currentBody = ProductsView(
          productService: widget.productService,
          categoryService: widget.categoryService,
          mediaUploadService: widget.mediaService,
        );
        break;
      case 4:
        currentBody = RbacView(
          rbacService: widget.rbacService,
        );
        break;
      default:
        currentBody = const SizedBox.shrink();
    }

    return JoppeResponsiveScaffold(
      title: 'Joppe Admin',
      selectedIndex: _selectedIndex,
      onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
      destinations: destinations,
      actions: [
        ActionChip(
          avatar: _profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 10,
                  backgroundImage: NetworkImage(_resolveImageUrl(_profile!.avatarUrl!)),
                  onBackgroundImageError: (_, _) {},
                )
              : const Icon(Icons.account_circle, size: 18),
          label: Text(widget.session.email),
          tooltip: 'Edit Profile (${widget.session.email})',
          onPressed: _openProfileDialog,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: JoppeSpacing.xs),
        Chip(
          label: Text(
            widget.session.role,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          backgroundColor: colorScheme.primaryContainer,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: JoppeSpacing.sm),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign Out',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out of Joppe Dashboard?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
                ],
              ),
            );
            if (confirm == true) {
              widget.authService.logout();
              widget.onLogout();
            }
          },
        ),
        const SizedBox(width: JoppeSpacing.sm),
      ],
      body: currentBody,
    );
  }
}
