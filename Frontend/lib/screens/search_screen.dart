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
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FIND A DISH', style: AppTextStyles.eyebrow),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    focusNode: _focus,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    style: AppTextStyles.body,
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
                ],
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
        title: 'Search the menu',
        message:
            'Type a dish name above. Results stream in 300ms after you stop '
            'typing.',
      );
    }
    if (_loading) {
      return const LoadingView(message: 'Cooking up results');
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: () => _runSearch(_query));
    }
    final results = _results;
    if (results == null || results.isEmpty) {
      return EmptyView(
        icon: Icons.no_food_rounded,
        title: 'No matches',
        message: 'Nothing on the menu matched "$_query".',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
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
