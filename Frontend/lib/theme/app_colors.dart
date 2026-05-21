import 'package:flutter/material.dart';

/// The app palette.
///
/// Every colour resolves against [brightness], which the app root keeps in
/// sync with the iOS light/dark setting. Because the members are getters,
/// every existing `AppColors.x` call site adapts automatically.
class AppColors {
  AppColors._();

  /// Current UI brightness — updated by the app root from the platform.
  static Brightness brightness = Brightness.light;

  static bool get isDark => brightness == Brightness.dark;

  /// Picks [light] or [dark] for the current [brightness].
  static Color _v(Color light, Color dark) => isDark ? dark : light;

  // ── Core palette ──
  static Color get cream =>
      _v(const Color(0xFFF5F0E8), const Color(0xFF14110A));
  static Color get espresso =>
      _v(const Color(0xFF1A1208), const Color(0xFFF3EDE1));

  /// Fixed dark ink — for text/borders on always-bright accents (e.g. lime).
  /// Unlike [espresso], it does not flip in dark mode.
  static const Color inkFixed = Color(0xFF1A1208);
  static Color get orange =>
      _v(const Color(0xFFD85A30), const Color(0xFFE86E40));
  static Color get tan =>
      _v(const Color(0xFFD4944A), const Color(0xFFDA9F5C));
  static Color get lime =>
      _v(const Color(0xFFC8F04A), const Color(0xFFCBEF5C));
  static Color get muted =>
      _v(const Color(0xFF5A4A30), const Color(0xFFAEA188));

  // ── Surfaces ──
  static Color get background => cream;
  static Color get surface =>
      _v(const Color(0xFFFBF8F2), const Color(0xFF221C12));
  static Color get surfaceSunk =>
      _v(const Color(0xFFEAE2D3), const Color(0xFF2C2417));

  /// Dark editorial panels — nav bar, ticker, hero app bars. Dark in both
  /// modes (a touch elevated above the background when dark).
  static Color get surfaceDark =>
      _v(const Color(0xFF1A1208), const Color(0xFF261F13));

  // ── Text ──
  static Color get textPrimary => espresso;
  static Color get textSecondary => muted;
  static Color get textMuted =>
      _v(const Color(0xFF8C7C64), const Color(0xFF938A78));

  /// Text/icons that sit on [surfaceDark] panels — light in both modes.
  static Color get textOnDark =>
      _v(const Color(0xFFF5F0E8), const Color(0xFFF3EDE1));

  // ── Accents & lines ──
  static Color get primary => orange;
  static Color get border =>
      _v(const Color(0x1F1A1208), const Color(0x24F3EDE1));
  static Color get borderStrong => espresso;
  static Color get danger =>
      _v(const Color(0xFFB23A1F), const Color(0xFFE36A4F));
  static Color get success =>
      _v(const Color(0xFF6F8F3A), const Color(0xFF8FB84A));
}
