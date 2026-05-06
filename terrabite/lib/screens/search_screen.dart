import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/meal.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/network_image_box.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Duration _debounce = Duration(milliseconds: 300);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounceTimer;

  String _query = '';
  bool _loading = false;
  String? _error;
  List<Meal>? _results;
  int _requestId = 0;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounceTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _query = '';
        _results = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounceTimer = Timer(_debounce, () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    final api = AppScope.of(context).api;
    final reqId = ++_requestId;
    setState(() {
      _query = query;
      _loading = true;
      _error = null;
    });

    try {
      final results = await api.searchMealsByName(query);
      if (!mounted || reqId != _requestId) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || reqId != _requestId) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceSm,
                AppTheme.spaceLg,
                AppTheme.spaceMd,
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Try "chicken", "pasta", or "Arrabiata"…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _clear,
                        ),
                ),
              ),
            ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_query.isEmpty) {
      return const EmptyView(
        icon: Icons.search_rounded,
        title: 'Search the meal database',
        message:
            'Type a dish name above. Results stream in 300ms after you stop typing.',
      );
    }
    if (_loading) {
      return const LoadingView(message: 'Cooking up results…');
    }
    if (_error != null) {
      return ErrorView(
        message: _error!,
        onRetry: () => _runSearch(_query),
      );
    }
    final results = _results;
    if (results == null || results.isEmpty) {
      return EmptyView(
        icon: Icons.no_food_rounded,
        title: 'No matches',
        message: 'Nothing in the database matched "$_query".',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceLg,
        0,
        AppTheme.spaceLg,
        AppTheme.spaceLg,
      ),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spaceSm),
      itemBuilder: (context, index) {
        final meal = results[index];
        return _SearchResultTile(
          meal: meal,
          onTap: () => context.push('/detail/${meal.id}', extra: meal),
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;

  const _SearchResultTile({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceSm),
          decoration: AppTheme.cardDecoration,
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: NetworkImageBox(
                  url: meal.thumbnailUrl,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Text(
                  meal.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
