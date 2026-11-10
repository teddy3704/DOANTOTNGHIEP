import 'package:flutter/material.dart';

/// Theme-aware colours for the older screens (V2-N18 / FINAL-F2): every
/// value follows light and dark mode instead of a fixed grey or black.
extension AppColors on BuildContext {
  ColorScheme get _scheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Secondary text and icons.
  Color get muted => _scheme.onSurfaceVariant;

  /// Primary text on a surface.
  Color get strong => _scheme.onSurface;

  /// Neutral panel or track behind content.
  Color get subtle => _scheme.surfaceContainerHigh;

  /// Thin borders and empty progress tracks.
  Color get hairline => _scheme.outlineVariant;

  /// Soft coloured card background; deep in dark mode so text stays readable.
  Color tint(MaterialColor c) => isDark
      ? Color.alphaBlend(c.withValues(alpha: .22), _scheme.surface)
      : c.shade50;

  /// Border that goes with [tint].
  Color tintBorder(MaterialColor c) => isDark ? c.shade700 : c.shade200;
}
