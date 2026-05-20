import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum PillTagVariant { solidDark, solidOrange, lime, ghostDark, ghostLight }

/// A small uppercase pill label — the SPLIT `.menu-item-tag` motif.
class PillTag extends StatelessWidget {
  final String label;
  final PillTagVariant variant;

  const PillTag({
    super.key,
    required this.label,
    this.variant = PillTagVariant.solidDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    Border? border;

    switch (variant) {
      case PillTagVariant.solidDark:
        bg = AppColors.espresso;
        fg = AppColors.cream;
      case PillTagVariant.solidOrange:
        bg = AppColors.orange;
        fg = AppColors.cream;
      case PillTagVariant.lime:
        bg = AppColors.lime;
        fg = AppColors.espresso;
        border = Border.all(color: AppColors.espresso, width: 1.5);
      case PillTagVariant.ghostDark:
        bg = Colors.transparent;
        fg = AppColors.espresso;
        border = Border.all(color: AppColors.espresso, width: 1.5);
      case PillTagVariant.ghostLight:
        bg = AppColors.cream.withValues(alpha: 0.1);
        fg = AppColors.cream;
        border = Border.all(
          color: AppColors.cream.withValues(alpha: 0.3),
          width: 1,
        );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border,
      ),
      child: Text(label.toUpperCase(), style: AppTextStyles.tag.copyWith(color: fg)),
    );
  }
}
