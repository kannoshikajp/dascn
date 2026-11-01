import 'package:flutter/material.dart';
import 'top_utility_bar.dart';
import 'main_header_bar.dart';
import 'navigation_tabs_bar.dart';

/// Khối Header tổng hợp hoàn chỉnh của Joppe E-Commerce
/// Bao gồm: Top Utility Bar + Main Header Bar + Navigation Tabs Bar
class JoppeHeader extends StatelessWidget {
  final VoidCallback? onCartTap;
  final VoidCallback? onAccountTap;
  final ValueChanged<String>? onSearch;
  final VoidCallback? onCategoryMenuTap;
  final ValueChanged<String>? onTabSelected;
  final VoidCallback? onLogoTap;

  const JoppeHeader({
    super.key,
    this.onCartTap,
    this.onAccountTap,
    this.onSearch,
    this.onCategoryMenuTap,
    this.onTabSelected,
    this.onLogoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TopUtilityBar(),
        MainHeaderBar(
          onCartTap: onCartTap,
          onAccountTap: onAccountTap,
          onSearch: onSearch,
          onLogoTap: onLogoTap,
        ),
        NavigationTabsBar(
          onCategoryMenuTap: onCategoryMenuTap,
          onTabSelected: onTabSelected,
        ),
      ],
    );
  }
}
