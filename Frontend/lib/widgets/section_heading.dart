import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// An eyebrow + oversized Syne title pairing, used as a section header.
class SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Color titleColor;
  final Color eyebrowColor;

  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.titleColor = AppColors.espresso,
    this.eyebrowColor = AppColors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(color: eyebrowColor),
        ),
        const SizedBox(height: 10),
        Text(title, style: AppTextStyles.display.copyWith(color: titleColor)),
      ],
    );
  }
}
