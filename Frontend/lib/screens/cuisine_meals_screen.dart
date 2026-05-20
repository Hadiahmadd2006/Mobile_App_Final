import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/meal.dart';
import '../theme/app_text_styles.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/meal_card.dart';
import '../widgets/pill_tag.dart';

/// Shows every dish for a given cuisine/area (TheMealDB `filter.php?a=`).
class CuisineMealsScreen extends StatefulWidget {
  final String area;

  const CuisineMealsScreen({super.key, required this.area});

  @override
  State<CuisineMealsScreen> createState() => _CuisineMealsScreenState();
}

class _CuisineMealsScreenState extends State<CuisineMealsScreen> {
  Future<List<Meal>>? _mealsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mealsFuture ??= AppScope.of(context).api.fetchMealsByArea(widget.area);
  }

  void _refresh() {
    setState(() {
      _mealsFuture = AppScope.of(context).api.fetchMealsByArea(widget.area);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.area),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<Meal>>(
          future: _mealsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Plating dishes');
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
                message: 'This cuisine has no recipes yet. Try another.',
              );
            }
            return _CuisineGrid(meals: meals, area: widget.area);
          },
        ),
      ),
    );
  }
}

class _CuisineGrid extends StatelessWidget {
  final List<Meal> meals;
  final String area;

  const _CuisineGrid({required this.meals, required this.area});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$area cuisine'.toUpperCase(),
                  style: AppTextStyles.eyebrow,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    PillTag(
                      label: '${meals.length} dishes',
                      variant: PillTagVariant.solidDark,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap any dish for the full recipe.',
                        style: AppTextStyles.bodyMuted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final meal = meals[index];
              return MealCard(
                meal: meal,
                onTap: () => context.push('/detail/${meal.id}', extra: meal),
              );
            }, childCount: meals.length),
          ),
        ),
      ],
    );
  }
}
