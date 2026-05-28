import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

/// Graphite design system — light and dark theme definitions.
///
/// Builds on [ColorScheme.fromSeed] for auto-generated surface variants,
/// then overrides specific tokens with [GraphiteColors] values.
// ignore_for_file: public_member_api_docs

abstract final class GraphiteTheme {
  // ── Light theme ───────────────────────────────────────────────────

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: GraphiteColors.graphite,
      brightness: Brightness.light,
    ).copyWith(
      primary: GraphiteColors.graphite,
      onPrimary: GraphiteColors.paper,
      secondary: GraphiteColors.blueLead,
      onSecondary: GraphiteColors.paper,
      tertiary: GraphiteColors.moss,
      onTertiary: GraphiteColors.paper,
      error: GraphiteColors.redPencil,
      onError: GraphiteColors.paper,
      surface: GraphiteColors.paper,
      onSurface: GraphiteColors.ink,
      surfaceContainerHighest: GraphiteColors.surfaceContainer,
      outline: GraphiteColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: GraphiteColors.background,
      cardColor: GraphiteColors.cardSurface,
      dividerColor: GraphiteColors.outline,
      appBarTheme: AppBarTheme(
        backgroundColor: GraphiteColors.graphite,
        foregroundColor: GraphiteColors.paper,
        elevation: 1,
        titleTextStyle: GraphiteTypography.title.copyWith(
          color: GraphiteColors.paper,
        ),
      ),
      cardTheme: CardThemeData(
        color: GraphiteColors.cardSurface,
        elevation: 1,
        shadowColor: GraphiteColors.ink.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_r),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GraphiteColors.moss.withValues(alpha: 0.15),
        labelStyle: GraphiteTypography.label.copyWith(
          color: GraphiteColors.moss,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_chipR),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GraphiteColors.graphite,
        foregroundColor: GraphiteColors.paper,
        elevation: 2,
        shape: CircleBorder(),
      ),
      textTheme: const TextTheme(
        displayLarge: GraphiteTypography.display,
        headlineMedium: GraphiteTypography.headline,
        titleLarge: GraphiteTypography.title,
        bodyLarge: GraphiteTypography.body,
        bodyMedium: GraphiteTypography.caption,
        labelMedium: GraphiteTypography.label,
        labelSmall: GraphiteTypography.overline,
      ),
    );
  }

  // ── Dark theme ────────────────────────────────────────────────────

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: GraphiteColors.paper,
      brightness: Brightness.dark,
    ).copyWith(
      primary: GraphiteColors.paper,
      onPrimary: GraphiteColors.graphite,
      secondary: GraphiteColors.blueLead,
      onSecondary: GraphiteColors.darkSurface,
      tertiary: GraphiteColors.moss,
      onTertiary: GraphiteColors.darkSurface,
      error: GraphiteColors.redPencil,
      onError: GraphiteColors.darkSurface,
      surface: GraphiteColors.darkSurface,
      onSurface: GraphiteColors.onDark,
      surfaceContainerHighest: GraphiteColors.darkSurfaceContainer,
      outline: GraphiteColors.darkOutline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: GraphiteColors.darkBackground,
      cardColor: GraphiteColors.darkCardSurface,
      dividerColor: GraphiteColors.darkOutline,
      appBarTheme: AppBarTheme(
        backgroundColor: GraphiteColors.darkSurface,
        foregroundColor: GraphiteColors.onDark,
        elevation: 1,
        titleTextStyle: GraphiteTypography.title.copyWith(
          color: GraphiteColors.onDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: GraphiteColors.darkCardSurface,
        elevation: 1,
        shadowColor: GraphiteColors.graphite.withValues(alpha: 0.30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_r),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: GraphiteColors.moss.withValues(alpha: 0.20),
        labelStyle: GraphiteTypography.label.copyWith(
          color: GraphiteColors.moss,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_chipR),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GraphiteColors.paper,
        foregroundColor: GraphiteColors.graphite,
        elevation: 2,
        shape: CircleBorder(),
      ),
      textTheme: const TextTheme(
        displayLarge: GraphiteTypography.display,
        headlineMedium: GraphiteTypography.headline,
        titleLarge: GraphiteTypography.title,
        bodyLarge: GraphiteTypography.body,
        bodyMedium: GraphiteTypography.caption,
        labelMedium: GraphiteTypography.label,
        labelSmall: GraphiteTypography.overline,
      ),
    );
  }

  // ── Constants ─────────────────────────────────────────────────────

  static const double _r = 8; // Card / input border radius.
  static const double _chipR = 4; // Chip border radius.
}
