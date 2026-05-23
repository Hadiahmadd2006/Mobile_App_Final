import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/michelin_recipes.dart';
import '../models/favorite_meal.dart';
import '../models/meal.dart';
import '../models/meal_detail.dart';
import '../models/michelin_recipe.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_box.dart';
import 'cooking_mode_screen.dart';

/// Pick a dish to launch Cooking Mode for.
///
/// Pulls together every dish the user can actually cook right now:
///   • Michelin (curated, structured steps)
///   • Favorites (saved from TheMealDB)
///   • Recently viewed
///   • Any TheMealDB recipe by name (debounced live search)
///
/// For non-Michelin rows we fetch the meal detail on tap and split its
/// `instructions` blob into discrete steps before opening Cooking Mode.
class CookingModeLauncherScreen extends StatefulWidget {
  const CookingModeLauncherScreen({super.key});

  @override
  State<CookingModeLauncherScreen> createState() =>
      _CookingModeLauncherScreenState();
}

class _CookingModeLauncherScreenState extends State<CookingModeLauncherScreen> {
  List<FavoriteMeal>? _favorites;
  List<Meal>? _recent;
  String _query = '';
  String? _busyMealId; // id currently being loaded for navigation

  // Debounced TheMealDB name search.
  Timer? _debounce;
  List<Meal>? _apiResults;
  bool _searching = false;
  String? _searchError;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    final fav = await scope.favorites.getAllFavorites();
    final recent = await scope.recentlyViewed.getRecent();
    if (!mounted) return;
    setState(() {
      _favorites = fav;
      _recent = recent;
    });
  }

  void _onQueryChanged(String v) {
    final q = v.trim();
    setState(() => _query = q);
    _debounce?.cancel();
    if (q.isEmpty) {
      setState(() {
        _apiResults = null;
        _searching = false;
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    final token = ++_searchToken;
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final results = await AppScope.of(context).api.searchMealsByName(q);
      if (!mounted || token != _searchToken) return;
      setState(() {
        _apiResults = results;
        _searching = false;
      });
    } catch (e) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _searching = false;
        _searchError = '$e';
      });
    }
  }

  bool _matches(String name) {
    if (_query.isEmpty) return true;
    return name.toLowerCase().contains(_query.toLowerCase());
  }

  Future<void> _openMichelin(MichelinRecipe recipe) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CookingModeScreen(
          title: recipe.name,
          steps: recipe.steps,
        ),
      ),
    );
  }

  Future<void> _openMealById(String id, String name) async {
    setState(() => _busyMealId = id);
    final api = AppScope.of(context).api;
    try {
      final MealDetail detail = await api.fetchMealDetail(id);
      final steps = splitInstructionsIntoSteps(detail.instructions);
      if (!mounted) return;
      if (steps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This recipe has no instructions to cook from.'),
          ),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CookingModeScreen(title: detail.name, steps: steps),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't load that recipe: $e")),
      );
    } finally {
      if (mounted) setState(() => _busyMealId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    final favIds = (_favorites ?? const <FavoriteMeal>[])
        .map((f) => f.id)
        .toSet();
    final recentFiltered = (_recent ?? const <Meal>[])
        .where((m) => !favIds.contains(m.id))
        .toList(growable: false);

    final michelinShown = kMichelinRecipes
        .where((r) => _matches(r.name))
        .toList(growable: false);
    final favoritesShown = (_favorites ?? const <FavoriteMeal>[])
        .where((f) => _matches(f.name))
        .toList(growable: false);
    final recentShown = recentFiltered
        .where((m) => _matches(m.name))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        title: Text(
          'Cooking Mode',
          style: AppTextStyles.heading.copyWith(fontSize: 26),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          children: [
            Text('Pick a dish', style: AppTextStyles.eyebrow),
            const SizedBox(height: 8),
            Text(
              'Big text, screen stays awake, quick timers built in.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 18),

            // ── Search field ───────────────────────────────────────────
            TextField(
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search all recipes…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                isDense: true,
              ),
            ),
            const SizedBox(height: 18),

            // ── Michelin ────────────────────────────────────────────────
            if (michelinShown.isNotEmpty) ...[
              _SectionHeader(
                label: 'Michelin Collection',
                count: michelinShown.length,
              ),
              const SizedBox(height: 10),
              for (final recipe in michelinShown) ...[
                _RecipeRow(
                  title: recipe.name,
                  subtitle: '${recipe.chef} · ${recipe.steps.length} steps',
                  imageUrl: recipe.imageUrl,
                  busy: false,
                  onTap: () => _openMichelin(recipe),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 18),
            ],

            // ── Favorites ───────────────────────────────────────────────
            _SectionHeader(
              label: 'Your favorites',
              count: _favorites?.length,
            ),
            const SizedBox(height: 10),
            if (_favorites == null)
              const _SkeletonHint()
            else if (favoritesShown.isEmpty)
              _EmptyHint(
                text: _favorites!.isEmpty
                    ? "You haven't favorited any dishes yet. Bookmark a "
                          'recipe and it shows up here.'
                    : 'No favorites match your search.',
              )
            else
              for (final f in favoritesShown) ...[
                _RecipeRow(
                  title: f.name,
                  subtitle: [
                    if (f.category.isNotEmpty) f.category,
                    if (f.area.isNotEmpty) f.area,
                  ].join(' · '),
                  imageUrl: f.thumbnailUrl,
                  busy: _busyMealId == f.id,
                  onTap: () => _openMealById(f.id, f.name),
                ),
                const SizedBox(height: 10),
              ],

            const SizedBox(height: 18),

            // ── Recently viewed ─────────────────────────────────────────
            _SectionHeader(
              label: 'Recently viewed',
              count: recentFiltered.length,
            ),
            const SizedBox(height: 10),
            if (_recent == null)
              const _SkeletonHint()
            else if (recentShown.isEmpty)
              _EmptyHint(
                text: recentFiltered.isEmpty
                    ? 'No recent dishes yet. Open any recipe and it lands '
                          'here.'
                    : 'No recent items match your search.',
              )
            else
              for (final m in recentShown) ...[
                _RecipeRow(
                  title: m.name,
                  subtitle: 'TheMealDB',
                  imageUrl: m.thumbnailUrl,
                  busy: _busyMealId == m.id,
                  onTap: () => _openMealById(m.id, m.name),
                ),
                const SizedBox(height: 10),
              ],

            // ── All recipes (TheMealDB search) ──────────────────────────
            if (_query.isNotEmpty) ...[
              const SizedBox(height: 18),
              _SectionHeader(
                label: 'All recipes',
                count: _apiResults?.length,
              ),
              const SizedBox(height: 10),
              if (_searching && _apiResults == null)
                const _SkeletonHint()
              else if (_searchError != null)
                _EmptyHint(text: "Couldn't search: $_searchError")
              else if ((_apiResults ?? const []).isEmpty)
                _EmptyHint(text: 'No recipes match "$_query".')
              else
                for (final m in _apiResults!) ...[
                  _RecipeRow(
                    title: m.name,
                    subtitle: 'TheMealDB',
                    imageUrl: m.thumbnailUrl,
                    busy: _busyMealId == m.id,
                    onTap: () => _openMealById(m.id, m.name),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int? count;

  const _SectionHeader({required this.label, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTextStyles.subheading),
        const SizedBox(width: 8),
        if (count != null)
          Text(
            '$count',
            style: AppTextStyles.label.copyWith(color: AppColors.muted),
          ),
      ],
    );
  }
}

class _RecipeRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool busy;
  final VoidCallback onTap;

  const _RecipeRow({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: AppTheme.card,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: NetworkImageBox(url: imageUrl),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.subheading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
                  ),
                )
              else
                Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.orange,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: AppTheme.card,
      child: Text(text, style: AppTextStyles.bodyMuted),
    );
  }
}

class _SkeletonHint extends StatelessWidget {
  const _SkeletonHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: AppTheme.card,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.muted),
            ),
          ),
          const SizedBox(width: 12),
          Text('Loading…', style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}
