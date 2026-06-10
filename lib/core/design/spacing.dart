import 'package:flutter/material.dart';

/// Graphite design system — spacing constants.
// ignore_for_file: public_member_api_docs

abstract final class GraphiteSpacing {
  /// 4px — tight, icon padding.
  static const double xs = 4;

  /// 8px — standard between related elements.
  static const double sm = 8;

  /// 12px — card internal padding.
  static const double md = 12;

  /// 16px — screen edge padding, section gaps.
  static const double lg = 16;

  /// 24px — large section separation.
  static const double xl = 24;

  /// 32px — page-level padding.
  static const double xxl = 32;

  // ── Component-specific ────────────────────────────────────────────

  /// Card border radius.
  static const double cardRadius = 8;

  /// Chip / pill border radius.
  static const double chipRadius = 4;

  /// Search bar / input border radius.
  static const double inputRadius = 8;

  /// FAB size.
  static const double fabSize = 56;

  /// Divider thickness.
  static const double dividerThickness = 1;

  /// Card padding — horizontal.
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  /// Card gap in list.
  static const double cardGap = lg;

  /// Horizontal page inset.
  static const double pageInset = 30;

  /// Compact page inset for narrow layouts.
  static const double compactPageInset = lg;
}
