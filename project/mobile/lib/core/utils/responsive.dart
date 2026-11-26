import 'package:flutter/material.dart';

/// Adaptive screen breakpoints aligned with `09_RESPONSIVE_AND_ADAPTIVE_DESIGN.md`.
abstract final class AfabBreakpoints {
  static const double smallPhoneMax = 359;
  static const double phoneMax = 599;
  static const double tabletPortraitMax = 839;
  static const double tabletRailExtendedMin = 1024;

  static bool isSmallPhone(double width) => width <= smallPhoneMax;
  static bool isPhone(double width) => width <= phoneMax;
  static bool isTablet(double width) => width > phoneMax;
  static bool isExpandedTablet(double width) => width > tabletPortraitMax;
  static bool isExtendedRail(double width) => width >= tabletRailExtendedMin;

  static int kpiColumnsForWidth(double width) {
    if (width < 360) return 1;
    if (width < 700) return 2;
    if (width < 1100) return 2;
    return 4;
  }
}

extension ResponsiveContextX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isPhoneLayout => AfabBreakpoints.isPhone(screenWidth);
  bool get isTabletLayout => AfabBreakpoints.isTablet(screenWidth);
}
