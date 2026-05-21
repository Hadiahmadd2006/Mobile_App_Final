import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography for the app, using the native iOS system font (San Francisco).
///
/// Styles are getters so their colours track the current [AppColors]
/// brightness (light/dark).
class AppTextStyles {
  AppTextStyles._();

  /// Optical "Display" cut of San Francisco — for large text (>= 20pt).
  static const String _display = 'CupertinoSystemDisplay';

  /// Optical "Text" cut of San Francisco — for body and UI text.
  static const String _text = 'CupertinoSystemText';

  /// The 'Syne' display font — kept only for the TerraBite brand wordmark.
  static TextStyle brand(double fontSize) => GoogleFonts.syne(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: AppColors.espresso,
    letterSpacing: -0.5,
  );

  // ── Display ──
  static TextStyle get hero => TextStyle(
    fontFamily: _display,
    fontSize: 52,
    fontWeight: FontWeight.w800,
    color: AppColors.espresso,
    height: 0.92,
    letterSpacing: -1.6,
  );

  static TextStyle get display => TextStyle(
    fontFamily: _display,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    color: AppColors.espresso,
    height: 0.96,
    letterSpacing: 0,
  );

  static TextStyle get heading => TextStyle(
    fontFamily: _display,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.espresso,
    letterSpacing: -0.5,
  );

  static TextStyle get subheading => TextStyle(
    fontFamily: _text,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.espresso,
    letterSpacing: -0.2,
  );

  // ── Body ──
  static TextStyle get body => TextStyle(
    fontFamily: _text,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
    height: 1.6,
  );

  static TextStyle get bodyMuted => TextStyle(
    fontFamily: _text,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.55,
  );

  static TextStyle get label => TextStyle(
    fontFamily: _text,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
    letterSpacing: 0.2,
  );

  // ── Accents ──
  static TextStyle get eyebrow => TextStyle(
    fontFamily: _text,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.orange,
    letterSpacing: 1.8,
  );

  static TextStyle get tag => TextStyle(
    fontFamily: _text,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.espresso,
    letterSpacing: 0.6,
  );

  static TextStyle get ticker => TextStyle(
    fontFamily: _text,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    letterSpacing: 1.2,
  );

  static TextStyle get button => TextStyle(
    fontFamily: _text,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );
}
