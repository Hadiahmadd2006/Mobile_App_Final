import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../widgets/pill_tag.dart';

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
          expandedHeight: 260,
          backgroundColor: AppColors.espresso,
          foregroundColor: AppColors.cream,
          flexibleSpace: FlexibleSpaceBar(
            background: previewThumb != null
                ? NetworkImageBox(url: previewThumb!)
                : const ColoredBox(color: AppColors.surfaceSunk),
          ),
          title: Text(
            previewName ?? 'Loading…',
            style: AppTextStyles.subheading.copyWith(color: AppColors.cream),
          ),
        ),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: LoadingView(message: 'Reading the recipe'),
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
  bool _recorded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkFavorite();
    if (!_recorded) {
      _recorded = true;
      final detail = widget.detail;
      AppScope.of(context).recentlyViewed.record(
        Meal(
          id: detail.id,
          name: detail.name,
          thumbnailUrl: detail.thumbnailUrl,
        ),
      );
    }
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
    final buffer = StringBuffer(
      '${detail.name} — a ${detail.area} '
      '${detail.category.toLowerCase()} recipe from TerraBite.',
    );
    final link = detail.sourceUrl ?? detail.youtubeUrl;
    if (link != null) buffer.write('\n$link');
    SharePlus.instance.share(
      ShareParams(text: buffer.toString(), subject: detail.name),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't open that link.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final estMinutes = (detail.ingredients.length * 3).clamp(15, 90);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 300,
          backgroundColor: AppColors.espresso,
          foregroundColor: AppColors.cream,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                NetworkImageBox(url: detail.thumbnailUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x731A1208),
                        Color(0x001A1208),
                        Color(0xE61A1208),
                      ],
                      stops: [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              detail.name,
              style: AppTextStyles.subheading.copyWith(color: AppColors.cream),
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
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.category.toUpperCase(),
                    style: AppTextStyles.eyebrow,
                  ),
                  const SizedBox(height: 8),
                  Text(detail.name, style: AppTextStyles.display),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.public_rounded,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(detail.area, style: AppTextStyles.label),
                      const SizedBox(width: 18),
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Text('~$estMinutes min', style: AppTextStyles.label),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ActionBar(
                    isFavorite: _isFavorite,
                    busy: _favoriteLoading,
                    onToggleFavorite: _toggleFavorite,
                    onShare: _share,
                  ),
                  if (detail.youtubeUrl != null ||
                      detail.sourceUrl != null) ...[
                    const SizedBox(height: 10),
                    _RecipeLinks(
                      youtubeUrl: detail.youtubeUrl,
                      sourceUrl: detail.sourceUrl,
                      onOpen: _openUrl,
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (detail.tags.isNotEmpty) ...[
                    const _SectionLabel(label: 'TAGS'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: detail.tags
                          .map(
                            (t) => PillTag(
                              label: t,
                              variant: PillTagVariant.ghostDark,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 28),
                  ],
                  const _SectionLabel(label: 'INGREDIENTS'),
                  const SizedBox(height: 12),
                  _IngredientsList(detail: detail),
                  const SizedBox(height: 28),
                  const _SectionLabel(label: 'INSTRUCTIONS'),
                  const SizedBox(height: 12),
                  Text(detail.instructions, style: AppTextStyles.body),
                  const SizedBox(height: 28),
                  const _SectionLabel(label: 'YOUR NOTES'),
                  const SizedBox(height: 12),
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
                  if (_isFavorite) ...[
                    const SizedBox(height: 18),
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
                ],
              ),
            ),
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
            label: Text(isFavorite ? 'Saved' : 'Save recipe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFavorite
                  ? AppColors.orange
                  : AppColors.espresso,
              foregroundColor: AppColors.cream,
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

class _RecipeLinks extends StatelessWidget {
  final String? youtubeUrl;
  final String? sourceUrl;
  final Future<void> Function(String url) onOpen;

  const _RecipeLinks({
    required this.onOpen,
    this.youtubeUrl,
    this.sourceUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (youtubeUrl != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onOpen(youtubeUrl!),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('Watch the video'),
            ),
          ),
        if (youtubeUrl != null && sourceUrl != null)
          const SizedBox(height: 10),
        if (sourceUrl != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onOpen(sourceUrl!),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('Original recipe'),
            ),
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
    return Row(
      children: [
        Container(
          width: 22,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.eyebrow),
      ],
    );
  }
}

class _IngredientsList extends StatelessWidget {
  final MealDetail detail;

  const _IngredientsList({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.card,
      child: Column(
        children: [
          for (var i = 0; i < detail.ingredients.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd,
                vertical: 13,
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.orange,
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
                              fontWeight: FontWeight.w700,
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
              const Divider(
                height: 1,
                indent: AppTheme.spaceMd,
                endIndent: AppTheme.spaceMd,
                color: AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}
