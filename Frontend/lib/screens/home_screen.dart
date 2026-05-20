import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/meal_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_card.dart';
import '../widgets/error_view.dart';
import '../widgets/fade_in_up.dart';
import '../widgets/loading_view.dart';
import '../widgets/marquee_ticker.dart';
import '../widgets/section_heading.dart';
import '../widgets/stickers.dart';

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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'TerraBite',
              style: AppTextStyles.heading.copyWith(fontSize: 21),
            ),
            const SizedBox(width: 5),
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
            ),
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
        top: false,
        child: FutureBuilder<List<MealCategory>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Stocking the pantry');
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
            return _HomeContent(categories: categories);
          },
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<MealCategory> categories;

  const _HomeContent({required this.categories});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: FadeInUp(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TONIGHT'S CRAVING", style: AppTextStyles.eyebrow),
                  const SizedBox(height: 12),
                  Text(
                    'WHAT ARE YOU\nIN THE MOOD FOR?',
                    style: AppTextStyles.display,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Browse ${categories.length} categories, then dig into '
                    'hundreds of recipes. No shortcuts.',
                    style: AppTextStyles.bodyMuted,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const StarSticker(text: 'FRESH\nPICKS', size: 80),
                      PillSticker(
                        text: '${categories.length} categories',
                        background: AppColors.lime,
                      ),
                      const PillSticker(
                        text: 'no shortcuts',
                        background: AppColors.orange,
                        foreground: AppColors.cream,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: MarqueeTicker(
            items: categories.map((c) => c.name).toList(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 14),
            child: const SectionHeading(
              eyebrow: 'The Menu',
              title: 'BROWSE BY\nCATEGORY',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 36),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
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
