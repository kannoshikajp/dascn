import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';
import '../views/overview_view.dart';
import '../views/users_view.dart';
import '../views/rbac_view.dart';
import '../views/categories_view.dart';

class DashboardShell extends StatefulWidget {
  final AuthSession session;
  final AuthService authService;
  final UserManagementService userService;
  final RbacManagementService rbacService;
  final CategoryManagementService categoryService;
  final VoidCallback onLogout;

  const DashboardShell({
    super.key,
    required this.session,
    required this.authService,
    required this.userService,
    required this.rbacService,
    required this.categoryService,
    required this.onLogout,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

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
          onNavigateToUsers: () => setState(() => _selectedIndex = 1),
          onNavigateToRbac: () => setState(() => _selectedIndex = 3),
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
        );
        break;
      case 3:
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
        Chip(
          avatar: const Icon(Icons.account_circle, size: 18),
          label: Text(widget.session.email),
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
