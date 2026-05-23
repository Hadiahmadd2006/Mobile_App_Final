import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../routing/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    final user = auth.currentUser;

    return Drawer(
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TerraBite',
                        style: AppTextStyles.heading.copyWith(fontSize: 26),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PREMIUM RECIPES · NO SHORTCUTS',
                    style: AppTextStyles.eyebrow.copyWith(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (user != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLg,
                ),
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.cardSoft,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: user.isAdmin
                          ? AppColors.espresso
                          : AppColors.orange.withValues(alpha: 0.2),
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName.characters.first.toUpperCase()
                            : '?',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 16,
                          color: user.isAdmin
                              ? AppColors.textOnDark
                              : AppColors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: AppTextStyles.subheading,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${user.isAdmin ? "Admin" : "User"} · '
                            '${user.isPro ? "Pro" : "Free"}',
                            style: AppTextStyles.label,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
            ],
            Divider(height: 1, color: AppColors.border),
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
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.settings);
              },
            ),
            if (auth.isAdmin)
              _DrawerItem(
                icon: Icons.shield_outlined,
                label: 'Admin Dashboard',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(AppRoutes.adminBase);
                },
              ),
            // TEMPORARY: preview the 404 screen via an unmatched route.
            _DrawerItem(
              icon: Icons.error_outline_rounded,
              label: 'Preview 404',
              onTap: () {
                Navigator.of(context).pop();
                context.go('/this-route-does-not-exist');
              },
            ),
            const Spacer(),
            Divider(height: 1, color: AppColors.border),
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
                      'A warm, editorial recipe explorer — browse categories, '
                      'search dishes, and save personal cooking notes for later.',
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                );
              },
            ),
            if (user != null)
              _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                destructive: true,
                onTap: () async {
                  Navigator.of(context).pop();
                  await auth.signOut();
                  if (context.mounted) context.go(AppRoutes.welcome);
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
  final bool destructive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.orange;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: AppTextStyles.subheading.copyWith(
          fontSize: 15,
          color: destructive ? AppColors.danger : null,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
    );
  }
}
