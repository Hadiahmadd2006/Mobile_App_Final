import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/meal_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_card.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<MealCategory>>? _categoriesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categoriesFuture ??= AppScope.of(context).api.fetchCategories();
  }

  void _refresh() {
    setState(() {
      _categoriesFuture = AppScope.of(context).api.fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('TerraBite'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<MealCategory>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Stocking the pantry…');
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }
            final categories = snapshot.data ?? const [];
            if (categories.isEmpty) {
              return ErrorView(
                message: 'No categories returned by the API.',
                onRetry: _refresh,
              );
            }
            return _CategoryGrid(categories: categories);
          },
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<MealCategory> categories;

  const _CategoryGrid({required this.categories});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TONIGHT\'S CRAVING',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.highlight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'What are you\nin the mood for?',
                  style: AppTextStyles.display,
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Text(
                  'Browse ${categories.length} categories — tap one to explore.',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceLg,
            AppTheme.spaceSm,
            AppTheme.spaceLg,
            AppTheme.spaceLg,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: AppTheme.spaceMd,
              crossAxisSpacing: AppTheme.spaceMd,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = categories[index];
                return CategoryCard(
                  category: category,
                  onTap: () => context.go(
                    '/home/category/${category.id}'
                    '?name=${Uri.encodeQueryComponent(category.name)}',
                  ),
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }
}
