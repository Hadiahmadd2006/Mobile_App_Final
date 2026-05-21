import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/meal.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/in_page_search_app_bar.dart';
import '../widgets/loading_view.dart';
import '../widgets/network_image_box.dart';

/// Full history of recipes the user has opened — newest first, stacked.
class RecentlyViewedScreen extends StatefulWidget {
  const RecentlyViewedScreen({super.key});

  @override
  State<RecentlyViewedScreen> createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  List<Meal> _recent = const [];
  bool _loaded = false;
  String _query = '';
  StreamSubscription<List<Meal>>? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscription != null) return;
    final repo = AppScope.of(context).recentlyViewed;
    repo.getRecent().then((list) {
      if (mounted) {
        setState(() {
          _recent = list;
          _loaded = true;
        });
      }
    });
    _subscription = repo.watch().listen((list) {
      if (mounted) {
        setState(() {
          _recent = list;
          _loaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<Meal> _applyQuery(List<Meal> meals) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return meals;
    return meals
        .where((meal) => meal.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild this screen when the iOS light/dark appearance changes.
    MediaQuery.platformBrightnessOf(context);
    return Scaffold(
      appBar: InPageSearchAppBar(
        title: 'Recently Viewed',
        large: true,
        hint: 'Search your history…',
        onChanged: (query) => setState(() => _query = query),
      ),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (!_loaded) {
      return LoadingView(message: 'Reading your history');
    }
    if (_recent.isEmpty) {
      return EmptyView(
        icon: Icons.history_rounded,
        title: 'Nothing here yet',
        message: 'Recipes you open will collect here so you can jump '
            'straight back to them.',
      );
    }
    final filtered = _applyQuery(_recent);
    if (filtered.isEmpty) {
      return EmptyView(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'None of your recent recipes match "$_query".',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      itemCount: filtered.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR HISTORY', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                Text(
                  '${filtered.length} recent '
                  '${filtered.length == 1 ? 'recipe' : 'recipes'}',
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 4),
                Text(
                  'The last dishes you opened, newest first.',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          );
        }
        return _RecentRow(meal: filtered[index - 1]);
      },
    );
  }
}

class _RecentRow extends StatelessWidget {
  final Meal meal;

  const _RecentRow({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/detail/${meal.id}', extra: meal),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: AppTheme.card,
          child: Row(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: NetworkImageBox(
                  url: meal.thumbnailUrl,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  meal.name,
                  style: AppTextStyles.subheading,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_outward_rounded,
                  color: AppColors.textOnDark,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
