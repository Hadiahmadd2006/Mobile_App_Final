import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../data/michelin_recipes.dart';
import '../models/favorite_meal.dart';
import '../models/meal.dart';
import '../models/michelin_recipe.dart';
import '../models/plan_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_box.dart';

/// 7-day Meal Planner. Three slots per day (Breakfast / Lunch / Dinner).
///
/// Each empty slot opens a bottom-sheet picker that lets the user choose
/// from Michelin dishes, their favorites, or recently viewed meals.
class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  late final List<DateTime> _days;
  late final String _startKey;
  late final String _endKey;

  Map<String, PlanEntry> _byKey = const {}; // "$date::$slot" → entry
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    _days = List.generate(7, (i) => base.add(Duration(days: i)));
    _startKey = _fmtDate(_days.first);
    _endKey = _fmtDate(_days.last);
    _load();
  }

  static String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _load() async {
    final repo = AppScope.of(context).mealPlan;
    final entries = await repo.getRange(_startKey, _endKey);
    if (!mounted) return;
    setState(() {
      _byKey = {for (final e in entries) '${e.date}::${e.slot.name}': e};
      _loaded = true;
    });
  }

  PlanEntry? _entryFor(DateTime day, PlanSlot slot) {
    return _byKey['${_fmtDate(day)}::${slot.name}'];
  }

  Future<void> _addToSlot(DateTime day, PlanSlot slot) async {
    // Capture the repo before showing the sheet so we don't read the
    // BuildContext after the await.
    final repo = AppScope.of(context).mealPlan;
    final picked = await showModalBottomSheet<_PickedMeal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RecipePickerSheet(),
    );
    if (picked == null) return;
    final entry = PlanEntry(
      date: _fmtDate(day),
      slot: slot,
      mealId: picked.id,
      mealName: picked.name,
      mealImage: picked.imageUrl,
      source: picked.source,
    );
    await repo.upsert(entry);
    if (!mounted) return;
    setState(() {
      _byKey = {..._byKey, '${entry.date}::${entry.slot.name}': entry};
    });
  }

  Future<void> _removeFromSlot(DateTime day, PlanSlot slot) async {
    final key = '${_fmtDate(day)}::${slot.name}';
    await AppScope.of(context).mealPlan.remove(_fmtDate(day), slot);
    if (!mounted) return;
    setState(() {
      final next = Map<String, PlanEntry>.from(_byKey)..remove(key);
      _byKey = next;
    });
  }

  void _openEntry(PlanEntry entry) {
    if (entry.isMichelin) {
      context.push('/pro/recipe/${entry.mealId}');
    } else {
      context.push('/detail/${entry.mealId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);

    final plannedCount = _byKey.length;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        title: Text(
          'Meal Planner',
          style: AppTextStyles.heading.copyWith(fontSize: 26),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
          children: [
            Text('This week', style: AppTextStyles.eyebrow),
            const SizedBox(height: 8),
            Text(
              _loaded
                  ? '$plannedCount '
                        '${plannedCount == 1 ? 'meal' : 'meals'} planned · '
                        '7 days'
                  : 'Loading your plan…',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 22),
            for (var i = 0; i < _days.length; i++) ...[
              _DayCard(
                date: _days[i],
                isToday: i == 0,
                entries: {
                  for (final s in PlanSlot.values) s: _entryFor(_days[i], s),
                },
                onAdd: (slot) => _addToSlot(_days[i], slot),
                onRemove: (slot) => _removeFromSlot(_days[i], slot),
                onTap: _openEntry,
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final Map<PlanSlot, PlanEntry?> entries;
  final void Function(PlanSlot slot) onAdd;
  final void Function(PlanSlot slot) onRemove;
  final void Function(PlanEntry entry) onTap;

  const _DayCard({
    required this.date,
    required this.isToday,
    required this.entries,
    required this.onAdd,
    required this.onRemove,
    required this.onTap,
  });

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final weekday = _weekdays[date.weekday - 1];
    final month = _months[date.month - 1];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: AppTheme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                isToday ? 'Today' : weekday,
                style: AppTextStyles.subheading,
              ),
              const SizedBox(width: 8),
              Text(
                '$month ${date.day}',
                style: AppTextStyles.label.copyWith(color: AppColors.muted),
              ),
              const Spacer(),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'TODAY',
                    style: AppTextStyles.tag.copyWith(
                      color: AppColors.textOnDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final slot in PlanSlot.values) ...[
            _SlotRow(
              slot: slot,
              entry: entries[slot],
              onAdd: () => onAdd(slot),
              onRemove: () => onRemove(slot),
              onTap: () {
                final e = entries[slot];
                if (e != null) onTap(e);
              },
            ),
            if (slot != PlanSlot.dinner) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final PlanSlot slot;
  final PlanEntry? entry;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _SlotRow({
    required this.slot,
    required this.entry,
    required this.onAdd,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) {
      return InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceSunk,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 78,
                child: Text(
                  slot.label,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ),
              Icon(Icons.add_rounded, color: AppColors.orange, size: 18),
              const SizedBox(width: 6),
              Text(
                'Add a recipe',
                style: AppTextStyles.label.copyWith(color: AppColors.orange),
              ),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSunk,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              child: Text(
                slot.label,
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: SizedBox(
                width: 44,
                height: 44,
                child: NetworkImageBox(url: e.mealImage),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.mealName,
                    style: AppTextStyles.subheading.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.isMichelin ? 'Michelin' : 'TheMealDB',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.muted,
              ),
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Picker sheet ────────────────────────────────────────────────────────

/// Light-weight payload returned by [_RecipePickerSheet] when a meal is
/// chosen. The sheet owns the picker UX; the planner just consumes the pick.
class _PickedMeal {
  final String id;
  final String name;
  final String imageUrl;
  final String source; // 'michelin' or 'mealdb'

  const _PickedMeal({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.source,
  });
}

class _RecipePickerSheet extends StatefulWidget {
  const _RecipePickerSheet();

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
  List<FavoriteMeal>? _favorites;
  List<Meal>? _recent;
  String _query = '';

  // Debounced TheMealDB name search.
  Timer? _debounce;
  List<Meal>? _apiResults;
  bool _searching = false;
  String? _searchError;
  int _searchToken = 0; // guards stale results

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

  void _pick(_PickedMeal m) => Navigator.of(context).pop(m);

  @override
  Widget build(BuildContext context) {
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

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: Row(
                children: [
                  Text('Pick a recipe', style: AppTextStyles.heading.copyWith(
                    fontSize: 22,
                  )),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: TextField(
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
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  if (michelinShown.isNotEmpty) ...[
                    _PickerSection(
                      label: 'Michelin Collection',
                      count: michelinShown.length,
                    ),
                    const SizedBox(height: 10),
                    for (final r in michelinShown) ...[
                      _PickerRow(
                        title: r.name,
                        subtitle: r.chef,
                        imageUrl: r.imageUrl,
                        onTap: () => _pick(_michelinPick(r)),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 14),
                  ],
                  _PickerSection(
                    label: 'Your favorites',
                    count: _favorites?.length,
                  ),
                  const SizedBox(height: 10),
                  if (_favorites == null)
                    const _LoadingHint()
                  else if (favoritesShown.isEmpty)
                    _EmptyHint(
                      text: _favorites!.isEmpty
                          ? "You haven't saved any favorites yet."
                          : 'No favorites match your search.',
                    )
                  else
                    for (final f in favoritesShown) ...[
                      _PickerRow(
                        title: f.name,
                        subtitle: [
                          if (f.category.isNotEmpty) f.category,
                          if (f.area.isNotEmpty) f.area,
                        ].join(' · '),
                        imageUrl: f.thumbnailUrl,
                        onTap: () => _pick(_PickedMeal(
                          id: f.id,
                          name: f.name,
                          imageUrl: f.thumbnailUrl,
                          source: 'mealdb',
                        )),
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 14),
                  _PickerSection(
                    label: 'Recently viewed',
                    count: recentFiltered.length,
                  ),
                  const SizedBox(height: 10),
                  if (_recent == null)
                    const _LoadingHint()
                  else if (recentShown.isEmpty)
                    _EmptyHint(
                      text: recentFiltered.isEmpty
                          ? 'Open a recipe to see it here later.'
                          : 'No recent items match your search.',
                    )
                  else
                    for (final m in recentShown) ...[
                      _PickerRow(
                        title: m.name,
                        subtitle: 'TheMealDB',
                        imageUrl: m.thumbnailUrl,
                        onTap: () => _pick(_PickedMeal(
                          id: m.id,
                          name: m.name,
                          imageUrl: m.thumbnailUrl,
                          source: 'mealdb',
                        )),
                      ),
                      const SizedBox(height: 8),
                    ],

                  // ── All recipes (TheMealDB search) ───────────────────
                  if (_query.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _PickerSection(
                      label: 'All recipes',
                      count: _apiResults?.length,
                    ),
                    const SizedBox(height: 10),
                    if (_searching && _apiResults == null)
                      const _LoadingHint()
                    else if (_searchError != null)
                      _EmptyHint(text: "Couldn't search: $_searchError")
                    else if ((_apiResults ?? const []).isEmpty)
                      _EmptyHint(text: 'No recipes match "$_query".')
                    else
                      for (final m in _apiResults!) ...[
                        _PickerRow(
                          title: m.name,
                          subtitle: 'TheMealDB',
                          imageUrl: m.thumbnailUrl,
                          onTap: () => _pick(_PickedMeal(
                            id: m.id,
                            name: m.name,
                            imageUrl: m.thumbnailUrl,
                            source: 'mealdb',
                          )),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  _PickedMeal _michelinPick(MichelinRecipe r) => _PickedMeal(
    id: r.id,
    name: r.name,
    imageUrl: r.imageUrl,
    source: 'michelin',
  );
}

class _PickerSection extends StatelessWidget {
  final String label;
  final int? count;

  const _PickerSection({required this.label, this.count});

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

class _PickerRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;

  const _PickerRow({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceSunk,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: NetworkImageBox(url: imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.subheading.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: AppTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.add_circle_outline_rounded,
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
      decoration: BoxDecoration(
        color: AppColors.surfaceSunk,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: AppTextStyles.bodyMuted),
    );
  }
}

class _LoadingHint extends StatelessWidget {
  const _LoadingHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunk,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
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
