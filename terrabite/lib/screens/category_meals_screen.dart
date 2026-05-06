import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/meal.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/meal_card.dart';

class CategoryMealsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryMealsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryMealsScreen> createState() => _CategoryMealsScreenState();
}

class _CategoryMealsScreenState extends State<CategoryMealsScreen> {
  Future<List<Meal>>? _mealsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mealsFuture ??= AppScope.of(context)
        .api
        .fetchMealsByCategory(widget.categoryName);
  }

  void _refresh() {
    setState(() {
      _mealsFuture = AppScope.of(context)
          .api
          .fetchMealsByCategory(widget.categoryName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Meal>>(
          future: _mealsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Plating dishes…');
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }
            final meals = snapshot.data ?? const [];
            if (meals.isEmpty) {
              return const EmptyView(
                icon: Icons.no_meals_rounded,
                title: 'No dishes here',
                message: 'This category is empty. Try another.',
              );
            }
            return _MealsGrid(meals: meals, categoryName: widget.categoryName);
          },
        ),
      ),
    );
  }
}

class _MealsGrid extends StatelessWidget {
  final List<Meal> meals;
  final String categoryName;

  const _MealsGrid({required this.meals, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLg,
            AppTheme.spaceMd,
            AppTheme.spaceLg,
            AppTheme.spaceMd,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '${meals.length} dishes',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLg,
            0,
            AppTheme.spaceLg,
            AppTheme.spaceLg,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: AppTheme.spaceMd,
              crossAxisSpacing: AppTheme.spaceMd,
              childAspectRatio: 0.78,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final meal = meals[index];
                return MealCard(
                  meal: meal,
                  onTap: () => context.push(
                    '/detail/${meal.id}',
                    extra: meal,
                  ),
                );
              },
              childCount: meals.length,
            ),
          ),
        ),
      ],
    );
  }
}
