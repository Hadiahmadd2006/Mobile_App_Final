import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the app theme for the current [AppColors.brightness] (light/dark)
/// and exposes shared spacing, radii and decorations.
class AppTheme {
  AppTheme._();

  // ── Spacing ──
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 40;

  // ── Radii ──
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;

  // ── Decorations ──
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: AppColors.espresso, width: 1.5),
  );

  static BoxDecoration get cardSoft => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: AppColors.border, width: 1),
  );

  static BoxDecoration get darkPanel => BoxDecoration(
    color: AppColors.surfaceDark,
    borderRadius: BorderRadius.circular(radiusLg),
  );

  static ThemeData build() {
    final isDark = AppColors.isDark;
    final base = ThemeData(
      brightness: AppColors.brightness,
      useMaterial3: true,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme:
          (isDark ? const ColorScheme.dark() : const ColorScheme.light())
              .copyWith(
                surface: AppColors.cream,
                primary: AppColors.orange,
                secondary: AppColors.espresso,
                error: AppColors.danger,
                onPrimary: AppColors.textOnDark,
                onSecondary: AppColors.cream,
                onSurface: AppColors.espresso,
              ),
      textTheme: base.textTheme.apply(
        fontFamily: 'CupertinoSystemText',
        bodyColor: AppColors.espresso,
        displayColor: AppColors.espresso,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.espresso,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.heading.copyWith(fontSize: 20),
        iconTheme: IconThemeData(color: AppColors.espresso),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: AppColors.cream),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: AppColors.espresso, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.orange,
        unselectedItemColor: AppColors.textOnDark.withValues(alpha: 0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.label.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.label.copyWith(fontSize: 11),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppTextStyles.bodyMuted.copyWith(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: AppColors.espresso, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: AppColors.espresso, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: AppColors.orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: AppColors.danger, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.espresso,
          foregroundColor: AppColors.cream,
          textStyle: AppTextStyles.button,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.espresso,
          backgroundColor: Colors.transparent,
          textStyle: AppTextStyles.button,
          side: BorderSide(color: AppColors.espresso, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.orange,
          textStyle: AppTextStyles.button,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.textOnDark,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.orange,
      ),
      dividerColor: AppColors.border,
      iconTheme: IconThemeData(color: AppColors.espresso),
    );
  }
}
