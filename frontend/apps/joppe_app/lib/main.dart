import 'package:flutter/material.dart';
import 'package:joppe_design_system/joppe_design_system.dart';

void main() {
  runApp(const JoppeApp());
}

class JoppeApp extends StatelessWidget {
  const JoppeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joppe Store',
      debugShowCheckedModeBanner: false,
      theme: JoppeTheme.light(),
      darkTheme: JoppeTheme.dark(),
      themeMode: ThemeMode.system,
      home: const CustomerHomePage(),
    );
  }
}

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _currentIndex = 0;

  static const List<JoppeNavigationDestination> _destinations = [
    JoppeNavigationDestination(
      icon: Icon(Icons.storefront_outlined),
      selectedIcon: Icon(Icons.storefront),
      label: 'Catalog',
    ),
    JoppeNavigationDestination(
      icon: Icon(Icons.build_circle_outlined),
      selectedIcon: Icon(Icons.build_circle),
      label: 'PC Builder',
    ),
    JoppeNavigationDestination(
      icon: Icon(Icons.shopping_cart_outlined),
      selectedIcon: Icon(Icons.shopping_cart),
      label: 'Cart',
    ),
    JoppeNavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return JoppeResponsiveScaffold(
      title: 'Joppe Store',
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
      destinations: _destinations,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {},
          tooltip: 'Search products',
        ),
      ],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _destinations[_currentIndex].icon is Icon
                  ? (_destinations[_currentIndex].selectedIcon as Icon).icon
                  : Icons.store,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: JoppeSpacing.md),
            Text(
              _destinations[_currentIndex].label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: JoppeSpacing.xs),
            Text(
              'Google Material 3 design system initialized.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
