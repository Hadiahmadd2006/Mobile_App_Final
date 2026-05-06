import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/favorite_meal.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/network_image_box.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: SafeArea(
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
                  return const LoadingView(message: 'Reading your shelf…');
                }
                final favorites = future.data ?? const [];
                if (favorites.isEmpty) {
                  return const EmptyView(
                    icon: Icons.bookmark_outline_rounded,
                    title: 'No favorites yet',
                    message:
                        'Tap "Save" on any recipe to keep it here with your '
                        'personal cooking notes.',
                  );
                }
                return _FavoritesList(favorites: favorites);
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
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      itemCount: favorites.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceMd),
      itemBuilder: (context, index) {
        final favorite = favorites[index];
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
        backgroundColor: AppColors.surfaceElevated,
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
          color: AppColors.danger.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Remove',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: AppColors.danger),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () => context.push('/detail/${favorite.id}'),
          onLongPress: () => context.push('/edit-note/${favorite.id}'),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            decoration: AppTheme.cardDecoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: NetworkImageBox(
                    url: favorite.thumbnailUrl,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.name,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${favorite.area} · ${favorite.category}',
                        style: AppTextStyles.label,
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
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
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
