import 'package:flutter/material.dart';

/// Graphite design system — typography scale.
///
/// All sizes and weights are sourced from the visual style guide.
// ignore_for_file: public_member_api_docs

abstract final class GraphiteTypography {
  // ── Display ───────────────────────────────────────────────────────

  /// Large heading — 28px bold.
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Section heading — 22px semi-bold.
  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  /// Card title / subtitle — 18px medium.
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // ── Body ──────────────────────────────────────────────────────────

  /// Body text — 16px regular.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Body emphasis — 16px semi-bold.
  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // ── Caption ───────────────────────────────────────────────────────

  /// Small body — 14px regular.
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Metadata / labels — 13px regular.
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  /// Fine print / overline — 11px regular.
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.5,
  );

  /// Tiny badge text — 10px medium.
  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.3,
  );

  // ── Monospace ─────────────────────────────────────────────────────

  /// Editor / code — 14px monospace.
  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );
}
