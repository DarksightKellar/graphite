import 'package:flutter/material.dart';

/// Graphite design system — color palette.
///
/// Inspired by graphite pencils, paper, and quiet craftsmanship.
/// All hex values are sourced from the visual style guide.
// ignore_for_file: public_member_api_docs

abstract final class GraphiteColors {
  // ── Core palette ──────────────────────────────────────────────────

  /// Primary — warm near-black (pencil lead).
  static const Color graphite = Color(0xFF2D2D2D);

  /// Surface — warm off-white (sketchbook paper).
  static const Color paper = Color(0xFFFAFAF6);

  /// On-surface text — deep charcoal.
  static const Color ink = Color(0xFF1A1A1A);

  // ── Accent palette ────────────────────────────────────────────────

  /// Accent — muted slate blue (colored pencil).
  static const Color blueLead = Color(0xFF5B7BB5);

  /// Destructive — muted brick red (markup pencil).
  static const Color redPencil = Color(0xFFC75B5B);

  /// Tertiary / tags — muted sage green.
  static const Color moss = Color(0xFF6B8E6B);

  // ── Surfaces ──────────────────────────────────────────────────────

  /// Card surface — slightly darker than paper for layering.
  static const Color cardSurface = Color(0xFFF2F2EE);

  /// Background behind cards.
  static const Color background = Color(0xFFEBEBE5);

  /// Surface variant for containers (toolbars, footer).
  static const Color surfaceContainer = Color(0xFFE0E0D8);

  /// Divider / outline.
  static const Color outline = Color(0xFFD6D6CE);

  // ── Dark palette ──────────────────────────────────────────────────

  /// Dark surface background.
  static const Color darkSurface = Color(0xFF1E1E1E);

  /// Dark card surface.
  static const Color darkCardSurface = Color(0xFF262626);

  /// Dark background.
  static const Color darkBackground = Color(0xFF171717);

  /// Dark divider.
  static const Color darkOutline = Color(0xFF3A3A3A);

  /// Dark surface variant.
  static const Color darkSurfaceContainer = Color(0xFF2E2E2E);

  // ── On-colors ─────────────────────────────────────────────────────

  /// Text on dark surfaces.
  static const Color onDark = Color(0xFFF0F0EC);

  /// Secondary text on dark surfaces.
  static const Color onDarkSecondary = Color(0xFFAAAAA4);

  /// Secondary text on light surfaces.
  static const Color onLightSecondary = Color(0xFF6B6B65);
}
