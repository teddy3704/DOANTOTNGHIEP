import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 36;
}

abstract final class AppRadius {
  static const double small = 12;
  static const double medium = 16;
  static const double large = 22;
  static const double pill = 999;
}

abstract final class AppLayout {
  static const double compactBreakpoint = 600;
  static const double wideBreakpoint = 900;
  static const double maxContentWidth = 1180;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.md,
    AppSpacing.lg,
    AppSpacing.xxl,
  );
}
