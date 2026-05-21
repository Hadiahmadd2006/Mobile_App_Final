import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/meal.dart';
import '../theme/app_text_styles.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/in_page_search_app_bar.dart';
import '../widgets/loading_view.dart';
import '../widgets/meal_card.dart';
import '../widgets/pill_tag.dart';

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
  String _query = '';

  List<Meal> _applyQuery(List<Meal> meals) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return meals;
    return meals
        .where((meal) => meal.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mealsFuture ??= AppScope.of(
      context,
    ).api.fetchMealsByCategory(widget.categoryName);
  }

  void _refresh() {
    setState(() {
      _mealsFuture = AppScope.of(
        context,
      ).api.fetchMealsByCategory(widget.categoryName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: InPageSearchAppBar(
        title: widget.categoryName,
        hint: 'Search ${widget.categoryName} dishes…',
        onChanged: (query) => setState(() => _query = query),
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
              return LoadingView(message: 'Plating dishes');
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }
            final meals = snapshot.data ?? const [];
            if (meals.isEmpty) {
              return EmptyView(
                icon: Icons.no_meals_rounded,
                title: 'No dishes here',
                message: 'This category is empty. Try another.',
              );
            }
            final filtered = _applyQuery(meals);
            if (filtered.isEmpty) {
              return EmptyView(
                icon: Icons.search_off_rounded,
                title: 'No matches',
                message: 'No dishes in ${widget.categoryName} '
                    'match "$_query".',
              );
            }
            return _MealsGrid(
              meals: filtered,
              categoryName: widget.categoryName,
            );
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
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(categoryName.toUpperCase(), style: AppTextStyles.eyebrow),
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
