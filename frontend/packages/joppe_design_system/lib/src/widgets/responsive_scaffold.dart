import 'package:flutter/material.dart';
import '../layout/breakpoints.dart';

class JoppeNavigationDestination {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? group;

  const JoppeNavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.group,
  });
}

/// Adaptive scaffold following Google Material 3 Window Size Classes.
class JoppeResponsiveScaffold extends StatefulWidget {
  final String title;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<JoppeNavigationDestination> destinations;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool? isCollapsed;
  final ValueChanged<bool>? onCollapseChanged;
  final bool initiallyCollapsed;
  final Widget? sidebarFooter;
  final Widget Function(BuildContext context, bool isCollapsed)? sidebarFooterBuilder;
  final String? collapseTooltip;
  final String? expandTooltip;

  const JoppeResponsiveScaffold({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.isCollapsed,
    this.onCollapseChanged,
    this.initiallyCollapsed = false,
    this.sidebarFooter,
    this.sidebarFooterBuilder,
    this.collapseTooltip,
    this.expandTooltip,
  });

  @override
  State<JoppeResponsiveScaffold> createState() => _JoppeResponsiveScaffoldState();
}

class _JoppeResponsiveScaffoldState extends State<JoppeResponsiveScaffold> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initiallyCollapsed;
  }

  @override
  void didUpdateWidget(covariant JoppeResponsiveScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCollapsed != null && widget.isCollapsed != oldWidget.isCollapsed) {
      _collapsed = widget.isCollapsed!;
    }
  }

  void _toggleCollapse() {
    final next = !_isEffectiveCollapsed;
    setState(() => _collapsed = next);
    widget.onCollapseChanged?.call(next);
  }

  bool get _isEffectiveCollapsed => widget.isCollapsed ?? _collapsed;

  @override
  Widget build(BuildContext context) {
    final sizeClass = JoppeBreakpoints.getWindowSizeClass(context);

    // Compact (<600dp): Bottom Navigation Bar
    if (sizeClass == JoppeWindowSizeClass.compact) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: widget.actions,
        ),
        body: widget.body,
        floatingActionButton: widget.floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.selectedIndex,
          onDestinationSelected: widget.onDestinationSelected,
          destinations: widget.destinations
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

    final colorScheme = Theme.of(context).colorScheme;
    final isCollapsed = _isEffectiveCollapsed;
    final sidebarWidth = isCollapsed ? 76.0 : 260.0;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: sidebarWidth,
            color: colorScheme.surface,
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 56,
                    padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 12),
                    alignment: Alignment.center,
                    child: isCollapsed
                        ? IconButton(
                            key: const ValueKey('sidebar_collapse_toggle'),
                            icon: const Icon(Icons.menu),
                            tooltip: widget.expandTooltip ?? 'Mở rộng',
                            onPressed: _toggleCollapse,
                          )
                        : Row(
                            children: [
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                key: const ValueKey('sidebar_collapse_toggle'),
                                icon: const Icon(Icons.menu_open),
                                tooltip: widget.collapseTooltip ?? 'Thu gọn',
                                onPressed: _toggleCollapse,
                              ),
                            ],
                          ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: _buildSidebarItems(context, isCollapsed),
                    ),
                  ),
                  if (widget.sidebarFooterBuilder != null || widget.sidebarFooter != null) ...[
                    const Divider(height: 1),
                    widget.sidebarFooterBuilder != null
                        ? widget.sidebarFooterBuilder!(context, isCollapsed)
                        : widget.sidebarFooter!,
                  ],
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(widget.destinations[widget.selectedIndex].label),
                actions: widget.actions,
              ),
              body: widget.body,
              floatingActionButton: widget.floatingActionButton,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSidebarItems(BuildContext context, bool isCollapsed) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <Widget>[];
    String? currentGroup;

    for (int i = 0; i < widget.destinations.length; i++) {
      final d = widget.destinations[i];
      final isSelected = i == widget.selectedIndex;

      if (d.group != null && d.group != currentGroup) {
        if (!isCollapsed) {
          items.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
              child: Text(
                d.group!.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      fontSize: 11,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        } else {
          if (items.isNotEmpty) {
            items.add(const Divider(height: 8, indent: 16, endIndent: 16));
          }
        }
        currentGroup = d.group;
      }

      if (isCollapsed) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            child: Tooltip(
              message: d.label,
              waitDuration: const Duration(milliseconds: 300),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => widget.onDestinationSelected(i),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: isSelected
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.secondaryContainer,
                            )
                          : null,
                      alignment: Alignment.center,
                      child: IconTheme(
                        data: IconThemeData(
                          size: 20,
                          color: isSelected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        child: isSelected ? (d.selectedIcon ?? d.icon) : d.icon,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            child: Material(
              color: isSelected ? colorScheme.secondaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => widget.onDestinationSelected(i),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      IconTheme(
                        data: IconThemeData(
                          size: 20,
                          color: isSelected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        child: isSelected ? (d.selectedIcon ?? d.icon) : d.icon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          d.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

    return items;
  }
}
