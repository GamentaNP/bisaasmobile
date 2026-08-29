library;

/// 4-pt grid — every spacing is a multiple of 4.
/// Redmi Note 12 (393dp) → 16dp outer padding = 4% of width (comfortable thumb reach).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Semantic
  static const double screenPadding = base;
  static const double cardPadding = base;
  static const double sectionGap = xxl;
  static const double itemGap = sm;
  static const double buttonPaddingH = lg;
  static const double buttonPaddingV = md;
}
