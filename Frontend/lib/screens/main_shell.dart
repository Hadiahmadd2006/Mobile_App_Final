import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _LiquidGlassTabBar(
        currentIndex: navigationShell.currentIndex,
        onSelectBranch: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Floating, capsule-shaped tab bar inspired by the iOS 26 "Liquid Glass"
/// system tab bar.
class _LiquidGlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelectBranch;

  const _LiquidGlassTabBar({
    required this.currentIndex,
    required this.onSelectBranch,
  });

  static const List<_TabItem> _items = [
    _TabItem(
      CupertinoIcons.square_grid_2x2,
      CupertinoIcons.square_grid_2x2_fill,
      'Home',
    ),
    _TabItem(CupertinoIcons.search, CupertinoIcons.search, 'Search'),
    _TabItem(CupertinoIcons.star, CupertinoIcons.star_fill, 'Pro'),
    _TabItem(CupertinoIcons.clock, CupertinoIcons.clock_fill, 'Recent'),
    _TabItem(
      CupertinoIcons.bookmark,
      CupertinoIcons.bookmark_fill,
      'Favorites',
    ),
  ];

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
                  for (int i = 0; i < _items.length; i++)
                    Expanded(
                      child: _TabButton(
                        item: _items[i],
                        selected: i == currentIndex,
                        onTap: () => onSelectBranch(i),
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

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _TabItem(this.icon, this.activeIcon, this.label);
}

class _TabButton extends StatelessWidget {
  final _TabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.item,
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
              selected ? item.activeIcon : item.icon,
              size: 22,
              color: selected
                  ? AppColors.orange
                  : AppColors.textOnDark.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
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
