import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'network_image_box.dart';

/// A meal grid card — photo on top, name and arrow on a cream footer.
///
/// When [locked] is true (Pro-gated for a free user) the image dims and a
/// "PRO" lock badge appears top-right. Tapping still fires [onTap] — the
/// detail screen decides what to show.
class MealCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  final bool locked;

  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
    this.locked = false,
  });

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkImageBox(url: meal.thumbnailUrl),
                    if (locked) ...[
                      // Dim the image so the locked state reads clearly.
                      Container(color: Colors.black.withValues(alpha: 0.35)),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: const _ProBadge(),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.espresso, width: 1.5),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        meal.name,
                        style: AppTextStyles.subheading,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: locked ? AppColors.muted : AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        locked
                            ? Icons.lock_rounded
                            : Icons.arrow_outward_rounded,
                        color: AppColors.textOnDark,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: AppColors.textOnDark),
          const SizedBox(width: 4),
          Text(
            'PRO',
            style: AppTextStyles.tag.copyWith(
              color: AppColors.textOnDark,
              letterSpacing: 1.2,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
