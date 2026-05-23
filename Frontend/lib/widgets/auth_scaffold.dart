import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'sunburst.dart';

/// Shared visual chrome for Welcome / Sign Up / Sign In.
///
/// Wraps content in a cream/dark scaffold, drops the TerraBite wordmark and
/// a faint sunburst behind it, and provides consistent padding. Each screen
/// supplies its own [title], optional [subtitle], the form body, and a
/// `footer` row for switching between auth modes.
class AuthScaffold extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? footer;
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.body,
    this.footer,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: showBack
          ? AppBar(
              backgroundColor: AppColors.cream,
              foregroundColor: AppColors.espresso,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: IgnorePointer(
                child: Sunburst(
                  size: 360,
                  color: AppColors.orange.withValues(alpha: 0.08),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceXl,
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TerraBite',
                      style: AppTextStyles.heading.copyWith(fontSize: 26),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceXl),
                Text(
                  eyebrow,
                  style: AppTextStyles.eyebrow,
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Text(
                  title,
                  style: AppTextStyles.display.copyWith(fontSize: 42),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spaceSm),
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 15),
                  ),
                ],
                const SizedBox(height: AppTheme.spaceLg + 4),
                body,
                if (footer != null) ...[
                  const SizedBox(height: AppTheme.spaceLg),
                  Center(child: footer),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline form-error banner that follows the TerraBite editorial card style.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.danger, width: 1.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(
                  color: AppColors.danger, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

