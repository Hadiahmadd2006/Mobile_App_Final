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
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Floating, capsule-shaped tab bar inspired by the iOS 26 "Liquid Glass"
/// system tab bar: a translucent rounded bar that hovers above the content
/// with a soft highlight pill behind the selected tab.
class _LiquidGlassTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LiquidGlassTabBar({required this.currentIndex, required this.onTap});

  static const List<_TabItem> _items = [
    _TabItem(
      icon: CupertinoIcons.square_grid_2x2,
      activeIcon: CupertinoIcons.square_grid_2x2_fill,
      label: 'Home',
    ),
    _TabItem(
      icon: CupertinoIcons.search,
      activeIcon: CupertinoIcons.search,
      label: 'Search',
    ),
    _TabItem(
      icon: CupertinoIcons.bookmark,
      activeIcon: CupertinoIcons.bookmark_fill,
      label: 'Favorites',
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
                color: AppColors.espresso.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: AppColors.cream.withValues(alpha: 0.1),
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
                        onTap: () => onTap(i),
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

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
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
                  ? AppColors.cream.withValues(alpha: 0.13)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              selected ? item.activeIcon : item.icon,
              size: 22,
              color: selected
                  ? AppColors.orange
                  : AppColors.cream.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: AppTextStyles.label.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.cream
                  : AppColors.cream.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
