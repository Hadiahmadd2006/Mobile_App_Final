import 'package:flutter/material.dart';

/// The SPLIT palette — a warm, editorial light theme.
///
/// Core values mirror the `:root` custom properties in the SPLIT landing
/// page (index.html): cream, espresso, orange, tan, lime, muted.
class AppColors {
  AppColors._();

  // ── Core SPLIT palette ──
  static const Color cream = Color(0xFFF5F0E8);
  static const Color espresso = Color(0xFF1A1208);
  static const Color orange = Color(0xFFD85A30);
  static const Color tan = Color(0xFFD4944A);
  static const Color lime = Color(0xFFC8F04A);
  static const Color muted = Color(0xFF5A4A30);

  // ── Surfaces ──
  static const Color background = cream;
  static const Color surface = Color(0xFFFBF8F2); // raised card on cream
  static const Color surfaceSunk = Color(0xFFEAE2D3); // inputs, image slots
  static const Color surfaceDark = espresso; // dark panels, nav, ticker

  // ── Text ──
  static const Color textPrimary = espresso;
  static const Color textSecondary = muted;
  static const Color textMuted = Color(0xFF8C7C64);
  static const Color textOnDark = cream;

  // ── Accents & lines ──
  static const Color primary = orange;
  static const Color border = Color(0x1F1A1208); // espresso @ ~12%
  static const Color borderStrong = espresso;
  static const Color danger = Color(0xFFB23A1F);
  static const Color success = Color(0xFF6F8F3A);
}
