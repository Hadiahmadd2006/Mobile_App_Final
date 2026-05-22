import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/meal.dart';
import '../models/meal_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/category_card.dart';
import '../widgets/error_view.dart';
import '../widgets/fade_in_up.dart';
import '../widgets/loading_view.dart';
import '../widgets/marquee_ticker.dart';
import '../widgets/network_image_box.dart';
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
    // Rebuild this screen when the iOS light/dark appearance changes.
    MediaQuery.platformBrightnessOf(context);
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'TerraBite',
              style: AppTextStyles.brand(21),
            ),
            const SizedBox(width: 5),
            Container(
              margin: const EdgeInsets.only(bottom: 5),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
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
          _GoProButton(),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<MealCategory>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return LoadingView(message: 'Stocking the pantry');
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
                    'What are you\nin the mood for?',
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
                      StarSticker(text: 'FRESH\nPICKS', size: 80),
                      PillSticker(
                        text: '${categories.length} categories',
                        background: AppColors.lime,
                        foreground: AppColors.inkFixed,
                        borderColor: AppColors.inkFixed,
                      ),
                      PillSticker(
                        text: 'no shortcuts',
                        background: AppColors.orange,
                        foreground: AppColors.textOnDark,
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
            child: SectionHeading(
              eyebrow: 'The Menu',
              title: 'Browse by\ncategory',
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
        SliverToBoxAdapter(child: _CuisineSection()),
        SliverToBoxAdapter(child: _RecentlyViewedSection()),
        SliverToBoxAdapter(child: _GoProSection()),
      ],
    );
  }
}

/// Continent grouping for TheMealDB cuisines/areas. Anything not listed
/// falls back to an "Other" bucket so new areas are never lost.
const Map<String, String> _continentByArea = {
  'British': 'Europe', 'Croatian': 'Europe', 'Dutch': 'Europe',
  'French': 'Europe', 'Greek': 'Europe', 'Irish': 'Europe',
  'Italian': 'Europe', 'Norwegian': 'Europe', 'Polish': 'Europe',
  'Portuguese': 'Europe', 'Russian': 'Europe', 'Spanish': 'Europe',
  'Turkish': 'Europe', 'Ukrainian': 'Europe',
  'Chinese': 'Asia', 'Filipino': 'Asia', 'Indian': 'Asia',
  'Japanese': 'Asia', 'Malaysian': 'Asia', 'Thai': 'Asia',
  'Vietnamese': 'Asia',
  'Egyptian': 'Africa', 'Kenyan': 'Africa', 'Moroccan': 'Africa',
  'Tunisian': 'Africa',
  'American': 'Americas', 'Canadian': 'Americas', 'Jamaican': 'Americas',
  'Mexican': 'Americas', 'Uruguayan': 'Americas',
};

const List<String> _continentOrder = [
  'Africa',
  'Americas',
  'Asia',
  'Europe',
  'Oceania',
  'Other',
];

/// Home section: cuisines grouped into expandable continent tiles.
class _CuisineSection extends StatefulWidget {
  const _CuisineSection();

  @override
  State<_CuisineSection> createState() => _CuisineSectionState();
}

class _CuisineSectionState extends State<_CuisineSection> {
  Future<List<String>>? _areasFuture;
  String? _expanded;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _areasFuture ??= AppScope.of(context).api.fetchAreas();
  }

  Map<String, List<String>> _groupByContinent(List<String> areas) {
    final grouped = <String, List<String>>{};
    for (final area in areas) {
      final continent = _continentByArea[area] ?? 'Other';
      grouped.putIfAbsent(continent, () => <String>[]).add(area);
    }
    for (final list in grouped.values) {
      list.sort();
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _areasFuture,
      builder: (context, snapshot) {
        final areas = snapshot.data ?? const <String>[];
        if (areas.isEmpty) return const SizedBox.shrink();
        final grouped = _groupByContinent(areas);
        final continents = _continentOrder.where(grouped.containsKey).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                eyebrow: 'Passport',
                title: 'Browse by\ncuisine',
              ),
              const SizedBox(height: 16),
              for (final continent in continents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ContinentTile(
                    continent: continent,
                    areas: grouped[continent]!,
                    expanded: _expanded == continent,
                    onToggle: () => setState(
                      () => _expanded =
                          _expanded == continent ? null : continent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// An expandable card for one continent; reveals its cuisines when tapped.
class _ContinentTile extends StatelessWidget {
  final String continent;
  final List<String> areas;
  final bool expanded;
  final VoidCallback onToggle;

  const _ContinentTile({
    required this.continent,
    required this.areas,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.espresso, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 15, 14, 15),
                child: Row(
                  children: [
                    Text(continent, style: AppTextStyles.subheading),
                    const Spacer(),
                    Text(
                      '${areas.length} cuisines',
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.espresso,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: [
                      for (final area in areas) ...[
                        Divider(height: 1, color: AppColors.border),
                        _CountryRow(area: area),
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// A single tappable cuisine row inside an expanded continent tile.
class _CountryRow extends StatelessWidget {
  final String area;

  const _CountryRow({required this.area});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/home/cuisine/${Uri.encodeComponent(area)}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(area, style: AppTextStyles.body)),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home section: a horizontal strip of recently opened recipes.
class _RecentlyViewedSection extends StatefulWidget {
  const _RecentlyViewedSection();

  @override
  State<_RecentlyViewedSection> createState() => _RecentlyViewedSectionState();
}

class _RecentlyViewedSectionState extends State<_RecentlyViewedSection> {
  List<Meal> _recent = const [];
  StreamSubscription<List<Meal>>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscription != null) return;
    final repo = AppScope.of(context).recentlyViewed;
    repo.getRecent().then((list) {
      if (mounted) setState(() => _recent = list);
    });
    _subscription = repo.watch().listen((list) {
      if (mounted) setState(() => _recent = list);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_recent.isEmpty) return const SizedBox.shrink();
    final shown = _recent.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: SectionHeading(
            eyebrow: 'Jump back in',
            title: 'Recently\nviewed',
          ),
        ),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _RecentCard(meal: shown[index]),
          ),
        ),
        const SizedBox(height: 36),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  final Meal meal;

  const _RecentCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/detail/${meal.id}', extra: meal),
      child: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
              width: 132,
              child: NetworkImageBox(
                url: meal.thumbnailUrl,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              meal.name,
              style: AppTextStyles.label.copyWith(
                color: AppColors.espresso,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact "Go Pro" pill in the Home app bar — free tier only.
class _GoProButton extends StatelessWidget {
  const _GoProButton();

  @override
  Widget build(BuildContext context) {
    final pro = AppScope.of(context).pro;
    return ListenableBuilder(
      listenable: pro,
      builder: (context, _) {
        if (pro.isPro) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: GestureDetector(
              onTap: () => context.go('/pro'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.textOnDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Go Pro',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The detailed "Go Pro" promo at the bottom of Home — free tier only.
class _GoProSection extends StatelessWidget {
  const _GoProSection();

  static const List<(IconData, String)> _details = [
    (Icons.star_rounded, 'Michelin Collection'),
    (Icons.calendar_month_rounded, 'Meal Planner'),
    (Icons.local_fire_department_rounded, 'Cooking Mode'),
    (Icons.menu_book_rounded, 'My Cookbook export'),
  ];

  @override
  Widget build(BuildContext context) {
    final pro = AppScope.of(context).pro;
    return ListenableBuilder(
      listenable: pro,
      builder: (context, _) {
        if (pro.isPro) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/pro'),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: AppTheme.darkPanel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TERRABITE PRO',
                      style: AppTextStyles.eyebrow.copyWith(
                        color: AppColors.lime,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Go Pro',
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Michelin-star recipes and a kit of pro cooking tools.',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final detail in _details) ...[
                      Row(
                        children: [
                          Icon(detail.$1, size: 16, color: AppColors.lime),
                          const SizedBox(width: 10),
                          Text(
                            detail.$2,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textOnDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Explore Pro',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.orange,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
