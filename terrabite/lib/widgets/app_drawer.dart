import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceMd,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TerraBite', style: AppTextStyles.heading),
                      Text(
                        'Recipe explorer',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.spaceSm),
            _DrawerItem(
              icon: Icons.grid_view_rounded,
              label: 'Browse Categories',
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.home);
              },
            ),
            _DrawerItem(
              icon: Icons.search_rounded,
              label: 'Search Recipes',
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.search);
              },
            ),
            _DrawerItem(
              icon: Icons.bookmark_rounded,
              label: 'My Favorites',
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.favorites);
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.info_outline_rounded,
              label: 'About TerraBite',
              onTap: () {
                Navigator.of(context).pop();
                showAboutDialog(
                  context: context,
                  applicationName: 'TerraBite',
                  applicationVersion: '1.0.0',
                  applicationLegalese:
                      'Recipes powered by TheMealDB. Built with Flutter.',
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'A clean, dark-themed recipe explorer that lets you '
                      'browse categories, search dishes, and save personal '
                      'cooking notes for later.',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.spaceSm),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: AppTextStyles.body),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
    );
  }
}
