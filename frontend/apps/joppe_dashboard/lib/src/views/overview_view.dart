import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

class OverviewView extends StatefulWidget {
  final UserManagementService userService;
  final RbacManagementService rbacService;
  final VoidCallback onNavigateToUsers;
  final VoidCallback onNavigateToRbac;

  const OverviewView({
    super.key,
    required this.userService,
    required this.rbacService,
    required this.onNavigateToUsers,
    required this.onNavigateToRbac,
  });

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  int _totalUsers = 0;
  int _activeUsers = 0;
  int _totalRoles = 0;
  int _totalPermissions = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await widget.userService.listUsers();
      final roles = await widget.rbacService.listRoles();
      final permissions = await widget.rbacService.listPermissions();

      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _activeUsers = users.where((u) => u.isActive).length;
          _totalRoles = roles.length;
          _totalPermissions = permissions.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: colorScheme.error),
            const SizedBox(height: JoppeSpacing.md),
            Text('Could not load statistics: $_error'),
            const SizedBox(height: JoppeSpacing.md),
            FilledButton(onPressed: _fetchStats, child: const Text('Retry Connection')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(JoppeSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Welcome
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(JoppeSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.dashboard_customize, size: 48, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: JoppeSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Joppe Admin Operations Center',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: JoppeSpacing.xs),
                        Text(
                          'Spring Boot 4.1.1 • Java 21 • PostgreSQL • Material You (M3)',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer.withAlpha(200),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _fetchStats,
                    icon: Icon(Icons.refresh, color: colorScheme.onPrimaryContainer),
                    tooltip: 'Refresh Stats',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: JoppeSpacing.lg),

          // Stat Cards
          GridView(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisExtent: 110,
              crossAxisSpacing: JoppeSpacing.md,
              mainAxisSpacing: JoppeSpacing.md,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                context,
                title: 'Total Users',
                value: '$_totalUsers',
                icon: Icons.people,
                color: colorScheme.primary,
                onTap: widget.onNavigateToUsers,
              ),
              _buildStatCard(
                context,
                title: 'Active Accounts',
                value: '$_activeUsers',
                icon: Icons.check_circle_outline,
                color: colorScheme.tertiary,
                onTap: widget.onNavigateToUsers,
              ),
              _buildStatCard(
                context,
                title: 'Defined Roles',
                value: '$_totalRoles',
                icon: Icons.security,
                color: colorScheme.secondary,
                onTap: widget.onNavigateToRbac,
              ),
              _buildStatCard(
                context,
                title: 'System Permissions',
                value: '$_totalPermissions',
                icon: Icons.key,
                color: colorScheme.primary,
                onTap: widget.onNavigateToRbac,
              ),
            ],
          ),
          const SizedBox(height: JoppeSpacing.lg),

          // System Capabilities & Quick Links
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(JoppeSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Backend Security & Compliance', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: JoppeSpacing.md),
                        _buildFeatureTile(
                          Icons.verified_user,
                          'Granular RBAC Enforced',
                          'Endpoints guarded by @PreAuthorize("hasAuthority(\'...\')") checking assigned role permissions.',
                        ),
                        const Divider(height: JoppeSpacing.md),
                        _buildFeatureTile(
                          Icons.swap_horiz,
                          'Strict Data Coupling',
                          'Controllers and services pass scalar types and flat records without entity leakage.',
                        ),
                        const Divider(height: JoppeSpacing.md),
                        _buildFeatureTile(
                          Icons.token,
                          'Stateless JWT Authentication',
                          'Tokens signed with HMAC-SHA256 containing user ID, role, and granted permissions.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: JoppeSpacing.md),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(JoppeSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Shortcuts', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: JoppeSpacing.md),
                        FilledButton.tonalIcon(
                          onPressed: widget.onNavigateToUsers,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Manage Accounts'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                        const SizedBox(height: JoppeSpacing.sm),
                        FilledButton.tonalIcon(
                          onPressed: widget.onNavigateToRbac,
                          icon: const Icon(Icons.shield),
                          label: const Text('Configure RBAC Matrix'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.md, vertical: JoppeSpacing.sm),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(35),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: JoppeSpacing.md),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24),
        const SizedBox(width: JoppeSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
