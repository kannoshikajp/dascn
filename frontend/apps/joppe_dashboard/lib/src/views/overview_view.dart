import 'package:flutter/material.dart';
import 'package:joppe_core/joppe_core.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

class OverviewView extends StatefulWidget {
  final UserManagementService userService;
  final RbacManagementService rbacService;
  final CategoryManagementService categoryService;
  final ProductManagementService productService;
  final VoidCallback onNavigateToUsers;
  final VoidCallback onNavigateToCategories;
  final VoidCallback onNavigateToProducts;
  final VoidCallback onNavigateToRbac;

  const OverviewView({
    super.key,
    required this.userService,
    required this.rbacService,
    required this.categoryService,
    required this.productService,
    required this.onNavigateToUsers,
    required this.onNavigateToCategories,
    required this.onNavigateToProducts,
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
  int _totalProducts = 0;
  int _activeProducts = 0;
  int _totalCategories = 0;
  int _activeCategories = 0;
  int _outOfStockCount = 0;
  List<ProductItem> _lowStockProducts = [];

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
      final results = await Future.wait([
        widget.userService.listUsers(),
        widget.rbacService.listRoles(),
        widget.rbacService.listPermissions(),
        widget.productService.listProducts(),
        widget.categoryService.listCategories(),
      ]);

      final users = results[0] as List<UserSummary>;
      final roles = results[1] as List<RoleItem>;
      final permissions = results[2] as List<PermissionItem>;
      final products = results[3] as List<ProductItem>;
      final categories = results[4] as List<CategoryItem>;

      final outOfStock = products.where((p) => p.totalStock <= 0).toList();
      final lowStock = products.where((p) => p.totalStock > 0 && p.totalStock <= 10).toList();

      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _activeUsers = users.where((u) => u.isActive).length;
          _totalRoles = roles.length;
          _totalPermissions = permissions.length;

          _totalProducts = products.length;
          _activeProducts = products.where((p) => p.isActive).length;

          _totalCategories = categories.length;
          _activeCategories = categories.where((c) => c.isActive).length;

          _outOfStockCount = outOfStock.length;
          _lowStockProducts = [...outOfStock, ...lowStock];

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

  String _formatPrice(double price) {
    if (price <= 0) return '0 ₫';
    final str = price.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join('')} ₫';
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
                          'Spring Boot 4.1.1 • OpenAPI / Swagger • PostgreSQL 16 • Material You',
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

          // Stat Cards Grid
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
                title: 'Total Products',
                subtitle: '$_activeProducts active catalog items',
                value: '$_totalProducts',
                icon: Icons.inventory_2,
                color: colorScheme.primary,
                onTap: widget.onNavigateToProducts,
              ),
              _buildStatCard(
                context,
                title: 'Active Categories',
                subtitle: '$_activeCategories active tree nodes',
                value: '$_totalCategories',
                icon: Icons.category,
                color: colorScheme.tertiary,
                onTap: widget.onNavigateToCategories,
              ),
              _buildStatCard(
                context,
                title: 'Total Users',
                subtitle: 'Registered accounts',
                value: '$_totalUsers',
                icon: Icons.people,
                color: colorScheme.secondary,
                onTap: widget.onNavigateToUsers,
              ),
              _buildStatCard(
                context,
                title: 'Active Accounts',
                subtitle: 'Enabled system users',
                value: '$_activeUsers',
                icon: Icons.check_circle_outline,
                color: colorScheme.tertiary,
                onTap: widget.onNavigateToUsers,
              ),
              _buildStatCard(
                context,
                title: 'Inventory Alert',
                subtitle: _outOfStockCount > 0
                    ? '$_outOfStockCount items out of stock'
                    : '${_lowStockProducts.length} low stock items',
                value: '${_lowStockProducts.length}',
                icon: _outOfStockCount > 0 ? Icons.error_outline : Icons.warning_amber_rounded,
                color: _outOfStockCount > 0 ? colorScheme.error : Colors.amber.shade800,
                onTap: widget.onNavigateToProducts,
              ),
              _buildStatCard(
                context,
                title: 'Defined Roles',
                subtitle: '$_totalPermissions permissions configured',
                value: '$_totalRoles',
                icon: Icons.shield,
                color: colorScheme.primary,
                onTap: widget.onNavigateToRbac,
              ),
            ],
          ),
          const SizedBox(height: JoppeSpacing.lg),

          // Main Layout Content: Left (Inventory & Low Stock) | Right (Shortcuts & API)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Inventory / Low Stock alert + System overview)
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    // Low Stock Alert Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(JoppeSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _lowStockProducts.isEmpty
                                      ? Icons.check_circle_outline
                                      : Icons.warning_amber_rounded,
                                  color: _lowStockProducts.isEmpty
                                      ? colorScheme.primary
                                      : (_outOfStockCount > 0 ? colorScheme.error : Colors.amber.shade800),
                                ),
                                const SizedBox(width: JoppeSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Inventory & Stock Alerts',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.arrow_forward, size: 16),
                                  label: const Text('Catalog'),
                                  onPressed: widget.onNavigateToProducts,
                                ),
                              ],
                            ),
                            const SizedBox(height: JoppeSpacing.sm),
                            if (_lowStockProducts.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(JoppeSpacing.md),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory, color: colorScheme.outline, size: 36),
                                    const SizedBox(width: JoppeSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Healthy Inventory Levels',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'All active products have adequate warehouse stock (> 10 items).',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _lowStockProducts.take(4).length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final p = _lowStockProducts[idx];
                                  final isOutOfStock = p.totalStock <= 0;

                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      backgroundColor: isOutOfStock
                                          ? colorScheme.errorContainer
                                          : Colors.amber.shade100,
                                      child: Icon(
                                        isOutOfStock ? Icons.remove_shopping_cart : Icons.inventory_2,
                                        size: 18,
                                        color: isOutOfStock
                                            ? colorScheme.onErrorContainer
                                            : Colors.amber.shade900,
                                      ),
                                    ),
                                    title: Text(
                                      p.productName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      '${p.variants.isNotEmpty ? p.variants.first.sku : p.slug} • ${_formatPrice(p.minPrice)}',
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        isOutOfStock ? '0 in stock' : '${p.totalStock} left',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isOutOfStock
                                              ? colorScheme.onErrorContainer
                                              : Colors.amber.shade900,
                                        ),
                                      ),
                                      backgroundColor: isOutOfStock
                                          ? colorScheme.errorContainer
                                          : Colors.amber.shade100,
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: JoppeSpacing.md),

                    // Architecture & Security Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(JoppeSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enterprise Architecture & Security',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: JoppeSpacing.sm),
                            _buildFeatureTile(
                              Icons.verified_user,
                              'Granular Role-Based Access Control (RBAC)',
                              '@PreAuthorize with permissions: CATALOG_WRITE, USER_MANAGE, ROLE_MANAGE.',
                            ),
                            const Divider(height: JoppeSpacing.sm),
                            _buildFeatureTile(
                              Icons.auto_stories,
                              'Nested Hierarchies & Multi-Category Tagging',
                              'Products can link to multiple category trees (Laptop, Gaming, Brand) with primary flag.',
                            ),
                            const Divider(height: JoppeSpacing.sm),
                            _buildFeatureTile(
                              Icons.tune,
                              'JSONB Structured Spec Variant Versioning',
                              'Independent SKUs, stock levels, and dynamic hardware attributes (RAM, GPU, CPU).',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: JoppeSpacing.md),

              // Right Column (Quick Shortcuts & OpenAPI Documentation)
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Quick Action Shortcuts Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(JoppeSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Management Shortcuts',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: JoppeSpacing.md),
                            FilledButton.tonalIcon(
                              onPressed: widget.onNavigateToProducts,
                              icon: const Icon(Icons.inventory_2_outlined),
                              label: const Text('Manage Products & Specs'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                            const SizedBox(height: JoppeSpacing.sm),
                            FilledButton.tonalIcon(
                              onPressed: widget.onNavigateToCategories,
                              icon: const Icon(Icons.category_outlined),
                              label: const Text('Manage Category Tree'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                            const SizedBox(height: JoppeSpacing.sm),
                            FilledButton.tonalIcon(
                              onPressed: widget.onNavigateToUsers,
                              icon: const Icon(Icons.people_outline),
                              label: const Text('Manage User Accounts'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                            const SizedBox(height: JoppeSpacing.sm),
                            FilledButton.tonalIcon(
                              onPressed: widget.onNavigateToRbac,
                              icon: const Icon(Icons.shield_outlined),
                              label: const Text('Configure RBAC Matrix'),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: JoppeSpacing.md),

                    // Swagger / OpenAPI Docs Card
                    Card(
                      color: colorScheme.surfaceContainerHigh,
                      child: Padding(
                        padding: const EdgeInsets.all(JoppeSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.api_outlined, color: Colors.teal),
                                const SizedBox(width: JoppeSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Web API Documentation',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: JoppeSpacing.xs),
                            Text(
                              'Swagger UI and OpenAPI 3.0 specs available for live testing:',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: JoppeSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UI: http://localhost:8080/swagger-ui.html',
                                    style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'JSON: http://localhost:8080/v3/api-docs',
                                    style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                                  ),
                                ],
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
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: JoppeSpacing.md, vertical: JoppeSpacing.xs),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withAlpha(35),
                foregroundColor: color,
                child: Icon(icon, size: 18),
              ),
              const SizedBox(width: JoppeSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16),
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
        Icon(icon, size: 20),
        const SizedBox(width: JoppeSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
