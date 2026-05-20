import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/meal.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recently Viewed')),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (!_loaded) {
      return const LoadingView(message: 'Reading your history');
    }
    if (_recent.isEmpty) {
      return const EmptyView(
        icon: Icons.history_rounded,
        title: 'Nothing here yet',
        message: 'Recipes you open will collect here so you can jump '
            'straight back to them.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      itemCount: _recent.length + 1,
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
                  '${_recent.length} recent '
                  '${_recent.length == 1 ? 'recipe' : 'recipes'}',
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
        return _RecentRow(meal: _recent[index - 1]);
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
                decoration: const BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  color: AppColors.cream,
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
