import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../app_scope.dart';
import '../models/favorite_meal.dart';
import '../services/cookbook_pdf_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/network_image_box.dart';

/// "Cookbook Export" — pick favorites, generate a PDF, share it.
///
/// Free users won't see this screen (the Pro hub card is the only entry
/// point), so no entitlement check is needed here.
class CookbookExportScreen extends StatefulWidget {
  const CookbookExportScreen({super.key});

  @override
  State<CookbookExportScreen> createState() => _CookbookExportScreenState();
}

class _CookbookExportScreenState extends State<CookbookExportScreen> {
  final CookbookPdfService _pdfService = CookbookPdfService();

  List<FavoriteMeal>? _favorites;
  final Set<String> _selected = <String>{};

  bool _exporting = false;
  String _progressLabel = '';
  double? _progress; // 0..1, null = indeterminate

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fav = await AppScope.of(context).favorites.getAllFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = fav;
      _selected
        ..clear()
        ..addAll(fav.map((f) => f.id));
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll(bool select) {
    setState(() {
      _selected.clear();
      if (select && _favorites != null) {
        _selected.addAll(_favorites!.map((f) => f.id));
      }
    });
  }

  Future<void> _export() async {
    final favs = _favorites ?? const <FavoriteMeal>[];
    final picked = favs.where((f) => _selected.contains(f.id)).toList();
    if (picked.isEmpty) return;

    final api = AppScope.of(context).api;
    setState(() {
      _exporting = true;
      _progress = 0;
      _progressLabel = 'Preparing…';
    });

    final bundles = <CookbookRecipe>[];
    for (var i = 0; i < picked.length; i++) {
      if (!mounted) return;
      final f = picked[i];
      setState(() {
        _progressLabel = 'Loading "${f.name}" (${i + 1}/${picked.length})';
        _progress = i / picked.length;
      });
      try {
        final detail = await api.fetchMealDetail(f.id);
        final imageBytes = await _pdfService.fetchImageBytes(f.thumbnailUrl);
        bundles.add(
          CookbookRecipe(
            detail: detail,
            noteTitle: f.noteTitle,
            noteBody: f.noteBody,
            imageBytes: imageBytes,
          ),
        );
      } catch (e) {
        // Skip recipes that fail — better than aborting the whole export.
        debugPrint('Cookbook export skipped ${f.id}: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _progressLabel = 'Building PDF…';
      _progress = null;
    });

    Uint8List bytes;
    try {
      bytes = await _pdfService.buildPdf(bundles);
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF build failed: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _progressLabel = 'Opening share sheet…';
    });

    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'terrabite_cookbook.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't open share: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          _progressLabel = '';
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);
    final favs = _favorites;
    final selectedCount = _selected.length;
    final totalCount = favs?.length ?? 0;
    final allSelected = totalCount > 0 && selectedCount == totalCount;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        title: Text(
          'Cookbook Export',
          style: AppTextStyles.heading.copyWith(fontSize: 26),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                children: [
                  Text('Your favorites', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 8),
                  Text(
                    favs == null
                        ? 'Loading…'
                        : favs.isEmpty
                            ? 'Save some recipes to Favorites first — '
                                  'they\'ll show up here ready to export.'
                            : '$selectedCount of $totalCount selected',
                    style: AppTextStyles.bodyMuted,
                  ),
                  const SizedBox(height: 12),
                  if (favs != null && favs.isNotEmpty)
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _exporting
                              ? null
                              : () => _selectAll(!allSelected),
                          icon: Icon(
                            allSelected
                                ? Icons.deselect_rounded
                                : Icons.select_all_rounded,
                            size: 18,
                          ),
                          label: Text(
                            allSelected ? 'Deselect all' : 'Select all',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  if (favs == null)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      decoration: AppTheme.card,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Loading…', style: AppTextStyles.bodyMuted),
                        ],
                      ),
                    )
                  else if (favs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      decoration: AppTheme.card,
                      child: Text(
                        'No favorites yet. Bookmark a few recipes, then '
                        'come back to export them as a PDF cookbook.',
                        style: AppTextStyles.body,
                      ),
                    )
                  else
                    for (final f in favs) ...[
                      _FavoriteRow(
                        favorite: f,
                        selected: _selected.contains(f.id),
                        onToggle: _exporting ? null : () => _toggle(f.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
            _ExportBar(
              enabled: !_exporting && selectedCount > 0,
              exporting: _exporting,
              progress: _progress,
              progressLabel: _progressLabel,
              selectedCount: selectedCount,
              onExport: _export,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  final FavoriteMeal favorite;
  final bool selected;
  final VoidCallback? onToggle;

  const _FavoriteRow({
    required this.favorite,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: AppTheme.card,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: NetworkImageBox(url: favorite.thumbnailUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite.name,
                      style: AppTextStyles.subheading.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (favorite.category.isNotEmpty) favorite.category,
                        if (favorite.area.isNotEmpty) favorite.area,
                      ].join(' · '),
                      style: AppTextStyles.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Checkbox(
                value: selected,
                onChanged: onToggle == null ? null : (_) => onToggle!(),
                activeColor: AppColors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportBar extends StatelessWidget {
  final bool enabled;
  final bool exporting;
  final double? progress;
  final String progressLabel;
  final int selectedCount;
  final VoidCallback onExport;

  const _ExportBar({
    required this.enabled,
    required this.exporting,
    required this.progress,
    required this.progressLabel,
    required this.selectedCount,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exporting) ...[
            Text(progressLabel, style: AppTextStyles.bodyMuted),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: enabled ? onExport : null,
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: Text(
                exporting
                    ? 'Exporting…'
                    : selectedCount == 0
                        ? 'Select recipes to export'
                        : 'Export $selectedCount ${selectedCount == 1 ? 'recipe' : 'recipes'} as PDF',
                style: AppTextStyles.button.copyWith(fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.textOnDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
