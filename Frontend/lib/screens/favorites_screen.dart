import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../data/pro_meals.dart';
import '../models/favorite_meal.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/in_page_search_app_bar.dart';
import '../widgets/loading_view.dart';
import '../widgets/network_image_box.dart';
import '../widgets/pro_lock_overlay.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _query = '';

  List<FavoriteMeal> _applyQuery(List<FavoriteMeal> favorites) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return favorites;
    return favorites
        .where((meal) => meal.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild this screen when the iOS light/dark appearance changes.
    MediaQuery.platformBrightnessOf(context);
    final repo = AppScope.of(context).favorites;

    return Scaffold(
      appBar: InPageSearchAppBar(
        title: 'Favorites',
        large: true,
        hint: 'Search your favorites…',
        onChanged: (query) => setState(() => _query = query),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<FavoriteMeal>>(
          stream: repo.watchFavorites(),
          builder: (context, snapshot) {
            return FutureBuilder<List<FavoriteMeal>>(
              future: snapshot.hasData
                  ? Future.value(snapshot.data!)
                  : repo.getAllFavorites(),
              builder: (context, future) {
                if (future.connectionState == ConnectionState.waiting &&
                    !future.hasData) {
                  return LoadingView(message: 'Reading your shelf');
                }
                final favorites = future.data ?? const [];
                if (favorites.isEmpty) {
                  return EmptyView(
                    icon: Icons.bookmark_outline_rounded,
                    title: 'No favorites yet',
                    message:
                        'Tap "Save" on any recipe to keep it here with your '
                        'personal cooking notes.',
                  );
                }
                final filtered = _applyQuery(favorites);
                if (filtered.isEmpty) {
                  return EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message: 'None of your favorites match "$_query".',
                  );
                }
                return _FavoritesList(favorites: filtered);
              },
            );
          },
        ),
      ),
    );
  }
}

class _FavoritesList extends StatelessWidget {
  final List<FavoriteMeal> favorites;

  const _FavoritesList({required this.favorites});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      itemCount: favorites.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceMd),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('YOUR SHELF', style: AppTextStyles.eyebrow),
                const SizedBox(height: 10),
                Text(
                  '${favorites.length} saved '
                  '${favorites.length == 1 ? 'recipe' : 'recipes'}',
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 4),
                Text(
                  'Swipe a card to remove it. Long-press to edit its note.',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          );
        }
        final favorite = favorites[index - 1];
        return _FavoriteTile(favorite: favorite);
      },
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final FavoriteMeal favorite;

  const _FavoriteTile({required this.favorite});

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove from favorites?'),
        content: Text(
          'This deletes "${favorite.name}" and your note. You can re-save it '
          'later from the recipe page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).favorites;

    return Dismissible(
      key: ValueKey('favorite-${favorite.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) async {
        await repo.deleteMeal(favorite.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${favorite.name}" removed.')),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppColors.espresso, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'REMOVE',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: AppColors.textOnDark),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () => context.push('/detail/${favorite.id}'),
          onLongPress: () => context.push('/edit-note/${favorite.id}'),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: AppTheme.card,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetworkImageBox(
                        url: favorite.thumbnailUrl,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      if (isMealPro(favorite.id) &&
                          !AppScope.of(context).pro.isPro)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: ProLockOverlay(size: 20),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.name,
                        style: AppTextStyles.subheading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${favorite.area} · ${favorite.category}'.toUpperCase(),
                        style: AppTextStyles.eyebrow.copyWith(
                          color: AppColors.muted,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        favorite.noteTitle,
                        style: AppTextStyles.bodyMuted.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit note',
                  icon: Icon(
                    Icons.edit_outlined,
                    color: AppColors.orange,
                  ),
                  onPressed: () => context.push('/edit-note/${favorite.id}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
