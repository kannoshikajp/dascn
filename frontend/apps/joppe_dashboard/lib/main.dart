import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  runApp(const JoppeDashboardApp());
}

class JoppeDashboardApp extends StatelessWidget {
  const JoppeDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joppe Dashboard',
      debugShowCheckedModeBanner: false,
      theme: JoppeTheme.light(),
      darkTheme: JoppeTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AdminDashboardPage(),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _currentIndex = 0;

  static const List<JoppeNavigationDestination> _destinations = [
    JoppeNavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Overview',
    ),
    JoppeNavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Catalog & Stock',
    ),
    JoppeNavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: 'Orders',
    ),
    JoppeNavigationDestination(
      icon: Icon(Icons.local_shipping_outlined),
      selectedIcon: Icon(Icons.local_shipping),
      label: 'Shipments',
    ),
    JoppeNavigationDestination(
      icon: Icon(Icons.admin_panel_settings_outlined),
      selectedIcon: Icon(Icons.admin_panel_settings),
      label: 'Users & RBAC',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return JoppeResponsiveScaffold(
      title: 'Joppe Control Center',
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
      destinations: _destinations,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            'AD',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      body: Padding(
        padding: const EdgeInsets.all(JoppeSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _destinations[_currentIndex].label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: JoppeSpacing.xs),
            Text(
              'Material 3 Adaptive Admin Suite',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: JoppeSpacing.lg),
            Expanded(
              child: Card(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: JoppeSpacing.md),
                      Text(
                        '${_destinations[_currentIndex].label} Workspace',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: JoppeSpacing.xs),
                      Text(
                        'Connected to Joppe Monorepo Design System',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
