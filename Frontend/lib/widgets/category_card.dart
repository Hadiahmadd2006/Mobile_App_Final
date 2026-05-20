import 'package:flutter/material.dart';

import '../models/meal_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'network_image_box.dart';

/// A bold poster-style category card in the SPLIT editorial look.
class CategoryCard extends StatelessWidget {
  final MealCategory category;
  final VoidCallback onTap;

  const CategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.espresso, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: AppColors.cream,
                child: NetworkImageBox(url: category.thumbnailUrl),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x661A1208),
                      Color(0xF21A1208),
                    ],
                    stops: [0.35, 0.62, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'EXPLORE',
                      style: AppTextStyles.eyebrow.copyWith(
                        color: AppColors.lime,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        category.name.toUpperCase(),
                        maxLines: 1,
                        softWrap: false,
                        style: AppTextStyles.heading.copyWith(
                          color: AppColors.cream,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: AppTheme.spaceMd,
                right: AppTheme.spaceMd,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.espresso, width: 2),
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    color: AppColors.cream,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
