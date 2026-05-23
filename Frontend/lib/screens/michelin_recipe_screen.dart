import 'package:flutter/material.dart';

import '../data/michelin_recipes.dart';
import '../models/michelin_recipe.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_box.dart';
import 'cooking_mode_screen.dart';

/// Detail view for a curated Michelin (Pro) recipe.
class MichelinRecipeScreen extends StatelessWidget {
  final String recipeId;

  const MichelinRecipeScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);
    final recipe = michelinRecipeById(recipeId);
    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Recipe not found.', style: AppTextStyles.body),
        ),
      );
    }
    return Scaffold(body: _RecipeContent(recipe: recipe));
  }
}

class _RecipeContent extends StatelessWidget {
  final MichelinRecipe recipe;

  const _RecipeContent({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 300,
          backgroundColor: AppColors.surfaceDark,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          leading: _HeroBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageBox(url: recipe.imageUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x73000000),
                        Color(0x00000000),
                        Color(0xE6000000),
                      ],
                      stops: [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              recipe.name,
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.textOnDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
          ),
        ),
        SliverToBoxAdapter(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Stars(count: recipe.stars),
                      const SizedBox(width: 10),
                      Text('MICHELIN', style: AppTextStyles.eyebrow),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(recipe.name, style: AppTextStyles.display),
                  const SizedBox(height: 12),
                  Text(recipe.tagline, style: AppTextStyles.bodyMuted),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spaceMd),
                    decoration: AppTheme.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.chef, style: AppTextStyles.subheading),
                        const SizedBox(height: 2),
                        Text(
                          '${recipe.restaurant} · ${recipe.location}',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CookingModeScreen(
                              title: recipe.name,
                              steps: recipe.steps,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 20,
                      ),
                      label: Text(
                        'Start Cooking Mode',
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: AppColors.textOnDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _Label(label: 'INGREDIENTS'),
                  const SizedBox(height: 12),
                  for (final ingredient in recipe.ingredients)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 7),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(ingredient, style: AppTextStyles.body),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  const _Label(label: 'METHOD'),
                  const SizedBox(height: 14),
                  for (var i = 0; i < recipe.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: AppTextStyles.tag.copyWith(
                                color: AppColors.textOnDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                recipe.steps[i],
                                style: AppTextStyles.body,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  final int count;

  const _Stars({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (_) => Icon(Icons.star_rounded, size: 18, color: AppColors.orange),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String label;

  const _Label({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.eyebrow),
      ],
    );
  }
}

/// Back-arrow with a soft dark backdrop so it stays legible on any photo
/// hero, regardless of light/dark mode or image tonality.
class _HeroBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HeroBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Material(
        color: Colors.black.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
