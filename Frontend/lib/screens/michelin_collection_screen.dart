import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/michelin_recipes.dart';
import '../models/michelin_recipe.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_box.dart';

/// The Pro "Michelin Collection" — curated fine-dining recipes.
class MichelinCollectionScreen extends StatelessWidget {
  const MichelinCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        title: Text(
          'Michelin Collection',
          style: AppTextStyles.heading.copyWith(fontSize: 26),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          children: [
            Text('The collection', style: AppTextStyles.eyebrow),
            const SizedBox(height: 8),
            Text(
              '${kMichelinRecipes.length} signature dishes from '
              'starred chefs.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 20),
            for (final recipe in kMichelinRecipes) ...[
              _MichelinCard(recipe: recipe),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _MichelinCard extends StatelessWidget {
  final MichelinRecipe recipe;

  const _MichelinCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/pro/recipe/${recipe.id}'),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          height: 200,
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
              NetworkImageBox(url: recipe.imageUrl),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00000000),
                      Color(0x99000000),
                      Color(0xF2000000),
                    ],
                    stops: [0.3, 0.62, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: List.generate(
                        recipe.stars,
                        (_) => Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.name,
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.textOnDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${recipe.chef} · ${recipe.restaurant}',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.82),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
