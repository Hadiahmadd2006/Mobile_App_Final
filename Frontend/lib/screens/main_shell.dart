import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _surpriseLoading = false;

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  Future<void> _surprise() async {
    if (_surpriseLoading) return;
    setState(() => _surpriseLoading = true);
    final api = AppScope.of(context).api;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final meal = await api.fetchRandomMeal();
      if (!mounted) return;
      router.push('/detail/${meal.id}');
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Couldn't find a recipe — try again."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _surpriseLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: _LiquidGlassTabBar(
        currentIndex: widget.navigationShell.currentIndex,
        surpriseLoading: _surpriseLoading,
        onSelectBranch: _goBranch,
        onSurprise: _surprise,
      ),
    );
  }
}

/// Floating, capsule-shaped tab bar inspired by the iOS 26 "Liquid Glass"
/// system tab bar. Hosts the three section tabs plus a "Surprise" action
/// that opens a random recipe.
class _LiquidGlassTabBar extends StatelessWidget {
  final int currentIndex;
  final bool surpriseLoading;
  final ValueChanged<int> onSelectBranch;
  final VoidCallback onSurprise;

  const _LiquidGlassTabBar({
    required this.currentIndex,
    required this.surpriseLoading,
    required this.onSelectBranch,
    required this.onSurprise,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: AppColors.textOnDark.withValues(alpha: 0.1),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      icon: CupertinoIcons.square_grid_2x2,
                      activeIcon: CupertinoIcons.square_grid_2x2_fill,
                      label: 'Home',
                      selected: currentIndex == 0,
                      onTap: () => onSelectBranch(0),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      icon: CupertinoIcons.search,
                      activeIcon: CupertinoIcons.search,
                      label: 'Search',
                      selected: currentIndex == 1,
                      onTap: () => onSelectBranch(1),
                    ),
                  ),
                  Expanded(
                    child: _SurpriseTabButton(
                      loading: surpriseLoading,
                      onTap: onSurprise,
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      icon: CupertinoIcons.clock,
                      activeIcon: CupertinoIcons.clock_fill,
                      label: 'Recent',
                      selected: currentIndex == 2,
                      onTap: () => onSelectBranch(2),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      icon: CupertinoIcons.bookmark,
                      activeIcon: CupertinoIcons.bookmark_fill,
                      label: 'Favorites',
                      selected: currentIndex == 3,
                      onTap: () => onSelectBranch(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.textOnDark.withValues(alpha: 0.13)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              selected ? activeIcon : icon,
              size: 22,
              color: selected
                  ? AppColors.orange
                  : AppColors.textOnDark.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.textOnDark
                  : AppColors.textOnDark.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// The action item that opens a random recipe. Styled like an unselected
/// section tab — it never takes the highlighted state.
class _SurpriseTabButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _SurpriseTabButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.textOnDark.withValues(alpha: 0.55);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SizedBox(
              width: 22,
              height: 22,
              child: loading
                  ? Padding(
                      padding: const EdgeInsets.all(2),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(tint),
                      ),
                    )
                  : Icon(Icons.casino_rounded, size: 22, color: tint),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Surprise',
            style: AppTextStyles.label.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDark.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
