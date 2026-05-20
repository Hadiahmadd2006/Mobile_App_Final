import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A SPLIT star sticker — a ten-point star badge with centered text.
class StarSticker extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final double size;
  final double rotation;

  const StarSticker({
    super.key,
    required this.text,
    this.background = AppColors.orange,
    this.foreground = AppColors.cream,
    this.size = 96,
    this.rotation = -0.14,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: ClipPath(
        clipper: _StarClipper(),
        child: Container(
          width: size,
          height: size,
          color: background,
          alignment: Alignment.center,
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.tag.copyWith(
              color: foreground,
              fontSize: size * 0.115,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarClipper extends CustomClipper<Path> {
  // Matches the clip-path polygon of `.sticker-star` in index.html.
  static const List<List<double>> _points = [
    [0.50, 0.00],
    [0.61, 0.35],
    [0.98, 0.35],
    [0.68, 0.57],
    [0.79, 0.91],
    [0.50, 0.70],
    [0.21, 0.91],
    [0.32, 0.57],
    [0.02, 0.35],
    [0.39, 0.35],
  ];

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(_points.first[0] * size.width, _points.first[1] * size.height);
    for (final p in _points.skip(1)) {
      path.lineTo(p[0] * size.width, p[1] * size.height);
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// A SPLIT pill sticker — a rounded, optionally outlined label tag.
class PillSticker extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final bool bordered;
  final double rotation;

  const PillSticker({
    super.key,
    required this.text,
    this.background = AppColors.lime,
    this.foreground = AppColors.espresso,
    this.bordered = true,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: bordered
              ? Border.all(color: AppColors.espresso, width: 2)
              : null,
        ),
        child: Text(
          text.toUpperCase(),
          style: AppTextStyles.tag.copyWith(
            color: foreground,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
