import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/chefs.dart';
import '../data/michelin_recipes.dart';
import '../models/michelin_recipe.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_box.dart';

/// Pro Chef Spotlights — Michelin recipes grouped by their chef, with a
/// short researched bio for each.
class ChefSpotlightsScreen extends StatelessWidget {
  const ChefSpotlightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    // Group recipes by chef, preserving the order they appear in the
    // collection so the most prominent chef shows first.
    final byChef = <String, List<MichelinRecipe>>{};
    for (final recipe in kMichelinRecipes) {
      byChef.putIfAbsent(recipe.chef, () => <MichelinRecipe>[]).add(recipe);
    }
    final chefs = byChef.keys.toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        title: Text(
          'Chef Spotlights',
          style: AppTextStyles.heading.copyWith(fontSize: 26),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          children: [
            Text('The chefs', style: AppTextStyles.eyebrow),
            const SizedBox(height: 8),
            Text(
              '${chefs.length} chefs · ${kMichelinRecipes.length} dishes',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < chefs.length; i++) ...[
              _ChefSection(chef: chefs[i], recipes: byChef[chefs[i]]!),
              if (i < chefs.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Divider(height: 1),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChefSection extends StatelessWidget {
  final String chef;
  final List<MichelinRecipe> recipes;

  const _ChefSection({required this.chef, required this.recipes});

  @override
  Widget build(BuildContext context) {
    final maxStars = recipes
        .map((r) => r.stars)
        .fold<int>(0, (a, b) => b > a ? b : a);
    final bio = chefBio(chef);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ChefAvatar(name: chef),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chef, style: AppTextStyles.subheading),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      for (var s = 0; s < maxStars; s++)
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.orange,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '${recipes.length} '
                        '${recipes.length == 1 ? 'dish' : 'dishes'}',
                        style: AppTextStyles.label,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (bio != null) ...[
          const SizedBox(height: 12),
          Text(bio, style: AppTextStyles.body),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _ChefRecipeCard(recipe: recipes[index]),
          ),
        ),
      ],
    );
  }
}

class _ChefAvatar extends StatelessWidget {
  final String name;

  const _ChefAvatar({required this.name});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.orange,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: AppTextStyles.tag.copyWith(
          color: AppColors.textOnDark,
          fontSize: 18,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ChefRecipeCard extends StatelessWidget {
  final MichelinRecipe recipe;

  const _ChefRecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pro/recipe/${recipe.id}'),
      child: SizedBox(
        width: 144,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 104,
              width: 144,
              child: NetworkImageBox(
                url: recipe.imageUrl,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recipe.name,
              style: AppTextStyles.label.copyWith(
                color: AppColors.espresso,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              recipe.restaurant,
              style: AppTextStyles.label.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
