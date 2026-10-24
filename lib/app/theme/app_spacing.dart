library;

import 'package:flutter/material.dart';

/// Spacing — the padding scale the screens actually use (4/8/12/16/20/24/32).
///
/// The theme owns color and type; this owns the gaps. A raw `EdgeInsets`
/// literal is not wrong, but six near-identical numbers spelled out across
/// 260 files is how gutters drift. New layout code reaches for these steps
/// first; a value that genuinely falls between the steps is a smell worth a
/// second look.
abstract final class AppSpacing {
  /// Icon ↔ label, tight chips.
  static const double xs = 4;

  /// Inside a chip, between stacked list rows.
  static const double sm = 8;

  /// Compact card inner padding.
  static const double md = 12;

  /// Card inner padding, screen gutters.
  static const double lg = 16;

  /// Section gaps, sheet content.
  static const double xl = 20;

  /// Screen-level blocks, modal padding.
  static const double xxl = 24;

  /// Hero sections, empty states.
  static const double xxxl = 32;

  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);

  /// The standard horizontal screen gutter.
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: lg);

  /// The standard card padding.
  static const EdgeInsets card = EdgeInsets.all(lg);
}
