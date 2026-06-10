import 'package:flutter/material.dart';

/// Graphite design system — typography scale.
///
/// All sizes and weights are sourced from the visual style guide.
// ignore_for_file: public_member_api_docs

abstract final class GraphiteTypography {
  static const String fontFamily = 'Inter';

  // ── Display ───────────────────────────────────────────────────────

  /// Brand/display heading — 56/64 bold.
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.bold,
    height: 64 / 56,
  );

  /// Screen heading — 32/40 bold.
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 40 / 32,
  );

  /// Section heading — 24/32 semi-bold.
  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  /// Card title / subtitle — 20/28 semi-bold.
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  // ── Body ──────────────────────────────────────────────────────────

  /// Body text — 16px regular.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  /// Body emphasis — 16px semi-bold.
  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );

  // ── Caption ───────────────────────────────────────────────────────

  /// Small body — 14px regular.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  /// Caption / metadata — 12/16 regular.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );

  /// Fine print / overline — 11px regular.
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Tiny badge text — 10px medium.
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0,
  );

  // ── Monospace ─────────────────────────────────────────────────────

  /// Editor / code — 14px monospace.
  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  // ── Markdown document headings ─────────────────────────────────────

  static const TextStyle markdownH1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
  );

  static const TextStyle markdownH2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 34 / 26,
  );

  static const TextStyle markdownH3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 30 / 22,
  );

  static const TextStyle markdownH4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 26 / 18,
  );

  static const TextStyle markdownH5 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );

  static const TextStyle markdownH6 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 22 / 14,
  );
}
