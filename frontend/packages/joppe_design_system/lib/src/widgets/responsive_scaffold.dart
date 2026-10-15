import 'package:flutter/material.dart';
import '../layout/breakpoints.dart';

class JoppeNavigationDestination {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;

  const JoppeNavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

/// Adaptive scaffold following Google Material 3 Window Size Classes.
class JoppeResponsiveScaffold extends StatelessWidget {
  final String title;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<JoppeNavigationDestination> destinations;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const JoppeResponsiveScaffold({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final sizeClass = JoppeBreakpoints.getWindowSizeClass(context);

    // Compact (<600dp): Bottom Navigation Bar
    if (sizeClass == JoppeWindowSizeClass.compact) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations
              .map(
                (d) => NavigationDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: d.label,
                ),
              )
              .toList(),
        ),
      );
    }

    // Medium (600dp - 840dp): Navigation Rail
    if (sizeClass == JoppeWindowSizeClass.medium) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.selected,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    // Expanded / Large (>=840dp): Permanent Navigation Drawer
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 16, 16),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const Divider(),
              ...destinations.map(
                (d) => NavigationDrawerDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                ),
              ),
            ],
          ),
          const VerticalDivider(),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(destinations[selectedIndex].label),
                actions: actions,
              ),
              body: body,
              floatingActionButton: floatingActionButton,
            ),
          ),
        ],
      ),
    );
  }
}
