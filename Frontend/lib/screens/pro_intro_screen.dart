import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// One-time celebratory teaser shown the first time a free user opens
/// the Pro tab. Mimics the "Talabat Pro" style sale poster — a tonal
/// background with a burst of accent ticks, a brand mark, and a
/// crossed-out before/after price.
///
/// Closes via the X chip top-left. There is no CTA here — the actual
/// upgrade happens on the paywall behind it.
class ProIntroScreen extends StatelessWidget {
  const ProIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    // Soft tinted backdrop based on the brand orange.
    final tint = AppColors.orange.withValues(alpha: 0.18);

    return Scaffold(
      backgroundColor: tint,
      body: Stack(
        children: [
          // Decorative ticks radiating from the centre.
          const Positioned.fill(child: _Burst()),

          // Close chip (top-left)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            child: _CloseChip(onTap: () => Navigator.of(context).pop()),
          ),

          // Main composition
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 60, 28, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 36),
                    Text(
                      'EGP 1188',
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 26,
                        decoration: TextDecoration.lineThrough,
                        decorationThickness: 3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'EGP 828',
                        style: AppTextStyles.hero.copyWith(
                          fontSize: 76,
                          color: AppColors.orange,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'when you join a yearly plan',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subheading.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'TAP THE X TO CONTINUE',
                      style: AppTextStyles.eyebrow.copyWith(
                        color: AppColors.muted,
                        fontSize: 11,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Brand mark ────────────────────────────────────────────────────────

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            'terrabite',
            style: AppTextStyles.heading.copyWith(
              color: AppColors.textOnDark,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.espresso,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            'pro',
            style: AppTextStyles.heading.copyWith(
              color: AppColors.cream,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Close chip ────────────────────────────────────────────────────────

class _CloseChip extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.close_rounded,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ── Decorative tick burst ─────────────────────────────────────────────

class _Burst extends StatelessWidget {
  const _Burst();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BurstPainter(color: AppColors.orange));
  }
}

class _BurstPainter extends CustomPainter {
  final Color color;

  _BurstPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    // Two concentric rings of ticks rotating to feel like a celebration.
    _drawRing(canvas, cx, cy, paint, count: 16, radius: 200, length: 22);
    _drawRing(
      canvas,
      cx,
      cy,
      paint..color = color.withValues(alpha: 0.35),
      count: 22,
      radius: 320,
      length: 30,
    );
  }

  void _drawRing(
    Canvas canvas,
    double cx,
    double cy,
    Paint paint, {
    required int count,
    required double radius,
    required double length,
  }) {
    for (var i = 0; i < count; i++) {
      final theta = (i / count) * 2 * math.pi;
      final dx = math.cos(theta);
      final dy = math.sin(theta);
      final start = Offset(cx + dx * radius, cy + dy * radius);
      final end = Offset(
        cx + dx * (radius + length),
        cy + dy * (radius + length),
      );
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.color != color;
}
