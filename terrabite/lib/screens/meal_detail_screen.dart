import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/favorite_meal.dart';
import '../models/meal.dart';
import '../models/meal_detail.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/network_image_box.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealId;
  final Meal? preview;

  const MealDetailScreen({super.key, required this.mealId, this.preview});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  Future<MealDetail>? _detailFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detailFuture ??= AppScope.of(context).api.fetchMealDetail(widget.mealId);
  }

  void _refresh() {
    setState(() {
      _detailFuture = AppScope.of(context).api.fetchMealDetail(widget.mealId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<MealDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _LoadingScaffold(
              previewName: widget.preview?.name,
              previewThumb: widget.preview?.thumbnailUrl,
            );
          }
          if (snapshot.hasError) {
            return _ErrorScaffold(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          final detail = snapshot.data;
          if (detail == null) {
            return _ErrorScaffold(
              message: 'Recipe not found.',
              onRetry: _refresh,
            );
          }
          return _DetailContent(detail: detail);
        },
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  final String? previewName;
  final String? previewThumb;

  const _LoadingScaffold({this.previewName, this.previewThumb});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 240,
          flexibleSpace: FlexibleSpaceBar(
            background: previewThumb != null
                ? NetworkImageBox(url: previewThumb!)
                : Container(color: AppColors.surfaceMuted),
          ),
          title: Text(previewName ?? 'Loading…'),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: LoadingView(message: 'Reading the recipe…'),
        ),
      ],
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScaffold({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(child: ErrorView(message: message, onRetry: onRetry)),
    );
  }
}

class _DetailContent extends StatefulWidget {
  final MealDetail detail;

  const _DetailContent({required this.detail});

  @override
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent> {
  bool _isFavorite = false;
  bool _favoriteLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final favorites = AppScope.of(context).favorites;
    final saved = await favorites.isFavorite(widget.detail.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = saved;
      _favoriteLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final favorites = AppScope.of(context).favorites;
    final messenger = ScaffoldMessenger.of(context);
    final detail = widget.detail;

    if (_isFavorite) {
      await favorites.deleteMeal(detail.id);
      if (!mounted) return;
      setState(() => _isFavorite = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Removed "${detail.name}" from favorites.')),
      );
    } else {
      await favorites.saveMeal(
        FavoriteMeal(
          id: detail.id,
          name: detail.name,
          thumbnailUrl: detail.thumbnailUrl,
          category: detail.category,
          area: detail.area,
          noteTitle: 'My note for ${detail.name}',
          noteBody: 'Add your thoughts, tweaks, or shopping notes here.',
          savedAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() => _isFavorite = true);
      messenger.showSnackBar(
        SnackBar(content: Text('Saved "${detail.name}" to favorites.')),
      );
    }
  }

  void _share() {
    final detail = widget.detail;
    final text =
        '${detail.name} — a ${detail.area} ${detail.category.toLowerCase()} '
        'recipe from TerraBite.';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe summary copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 280,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageBox(url: detail.thumbnailUrl),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.background.withValues(alpha: 0.3),
                        AppColors.background.withValues(alpha: 0.0),
                        AppColors.background.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              detail.name,
              style: AppTextStyles.subheading.copyWith(
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
          ),
        ),
        SliverToBoxAdapter(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceXl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaRow(detail: detail),
                  const SizedBox(height: AppTheme.spaceLg),
                  _ActionBar(
                    isFavorite: _isFavorite,
                    busy: _favoriteLoading,
                    onToggleFavorite: _toggleFavorite,
                    onShare: _share,
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  if (detail.tags.isNotEmpty) ...[
                    _SectionLabel(label: 'TAGS'),
                    const SizedBox(height: AppTheme.spaceSm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: detail.tags
                          .map((t) => _Chip(label: t))
                          .toList(),
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                  ],
                  _SectionLabel(label: 'INGREDIENTS'),
                  const SizedBox(height: AppTheme.spaceSm),
                  _IngredientsList(detail: detail),
                  const SizedBox(height: AppTheme.spaceLg),
                  _SectionLabel(label: 'INSTRUCTIONS'),
                  const SizedBox(height: AppTheme.spaceSm),
                  Text(detail.instructions, style: AppTextStyles.body),
                  const SizedBox(height: AppTheme.spaceLg),
                  _SectionLabel(label: 'YOUR NOTES'),
                  const SizedBox(height: AppTheme.spaceSm),
                  TextField(
                    enabled: false,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: _isFavorite
                          ? 'Open from Favorites to edit your notes.'
                          : 'Save this recipe to add personal notes.',
                      prefixIcon: const Icon(
                        Icons.sticky_note_2_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  if (_isFavorite)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/edit-note/${detail.id}'),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit personal note'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final MealDetail detail;

  const _MetaRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.surfaceMuted,
          foregroundColor: AppColors.primary,
          child: const Icon(Icons.restaurant_rounded, size: 24),
        ),
        const SizedBox(width: AppTheme.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.category.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.highlight,
                ),
              ),
              const SizedBox(height: 2),
              Text(detail.name, style: AppTextStyles.heading),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.public_rounded,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(detail.area, style: AppTextStyles.bodyMuted),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '~${(detail.ingredients.length * 3).clamp(15, 90)} min',
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool isFavorite;
  final bool busy;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShare;

  const _ActionBar({
    required this.isFavorite,
    required this.busy,
    required this.onToggleFavorite,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: busy ? null : onToggleFavorite,
            icon: Icon(
              isFavorite ? Icons.bookmark_rounded : Icons.bookmark_add_outlined,
              size: 18,
            ),
            label: Text(isFavorite ? 'Saved' : 'Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFavorite
                  ? AppColors.surfaceElevated
                  : AppColors.primary,
              foregroundColor: isFavorite
                  ? AppColors.primary
                  : Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          label: const Text('Share'),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(color: AppColors.highlight),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: AppTextStyles.label),
    );
  }
}

class _IngredientsList extends StatelessWidget {
  final MealDetail detail;

  const _IngredientsList({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          for (var i = 0; i < detail.ingredients.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.body,
                        children: [
                          TextSpan(
                            text: detail.ingredients[i].name,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (detail.ingredients[i].measure.isNotEmpty)
                            TextSpan(
                              text: '   ·   ${detail.ingredients[i].measure}',
                              style: AppTextStyles.bodyMuted,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < detail.ingredients.length - 1)
              const Divider(height: 1, indent: AppTheme.spaceMd),
          ],
        ],
      ),
    );
  }
}
