import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography for the SPLIT look: Syne for bold editorial display,
/// Space Grotesk for body and UI text.
class AppTextStyles {
  AppTextStyles._();

  // ── Display — Syne ──
  static TextStyle get hero => GoogleFonts.syne(
    fontSize: 52,
    fontWeight: FontWeight.w800,
    color: AppColors.espresso,
    height: 0.92,
    letterSpacing: -1.6,
  );

  static TextStyle get display => GoogleFonts.syne(
    fontSize: 38,
    fontWeight: FontWeight.w800,
    color: AppColors.espresso,
    height: 0.96,
    letterSpacing: -1.0,
  );

  static TextStyle get heading => GoogleFonts.syne(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.espresso,
    letterSpacing: -0.5,
  );

  static TextStyle get subheading => GoogleFonts.syne(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.espresso,
    letterSpacing: -0.2,
  );

  // ── Body — Space Grotesk ──
  static TextStyle get body => GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.espresso,
    height: 1.6,
  );

  static TextStyle get bodyMuted => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.55,
  );

  static TextStyle get label => GoogleFonts.spaceGrotesk(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.muted,
    letterSpacing: 0.2,
  );

  // ── Accents ──
  static TextStyle get eyebrow => GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.orange,
    letterSpacing: 1.8,
  );

  static TextStyle get tag => GoogleFonts.syne(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.espresso,
    letterSpacing: 0.6,
  );

  static TextStyle get ticker => GoogleFonts.syne(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.cream,
    letterSpacing: 1.2,
  );

  static TextStyle get button => GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );
}
