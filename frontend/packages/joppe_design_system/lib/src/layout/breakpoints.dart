import 'package:flutter/widgets.dart';

/// Google Material 3 Window Size Classes.
enum JoppeWindowSizeClass {
  compact,
  medium,
  expanded,
  large,
  extraLarge,
}

class JoppeBreakpoints {
  JoppeBreakpoints._();

  static const double compactMax = 600.0;
  static const double mediumMax = 840.0;
  static const double expandedMax = 1200.0;
  static const double largeMax = 1600.0;

  static JoppeWindowSizeClass getWindowSizeClass(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < compactMax) return JoppeWindowSizeClass.compact;
    if (width < mediumMax) return JoppeWindowSizeClass.medium;
    if (width < expandedMax) return JoppeWindowSizeClass.expanded;
    if (width < largeMax) return JoppeWindowSizeClass.large;
    return JoppeWindowSizeClass.extraLarge;
  }

  static bool isCompact(BuildContext context) =>
      getWindowSizeClass(context) == JoppeWindowSizeClass.compact;

  static bool isMedium(BuildContext context) =>
      getWindowSizeClass(context) == JoppeWindowSizeClass.medium;

  static bool isExpandedOrLarger(BuildContext context) {
    final windowClass = getWindowSizeClass(context);
    return windowClass == JoppeWindowSizeClass.expanded ||
        windowClass == JoppeWindowSizeClass.large ||
        windowClass == JoppeWindowSizeClass.extraLarge;
  }
}
