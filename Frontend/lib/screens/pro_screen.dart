import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// The Pro tab: a paywall on the free tier, or the Pro hub once unlocked.
class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);
    final pro = AppScope.of(context).pro;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        title: Text(
          'TerraBite Pro',
          style: AppTextStyles.heading.copyWith(fontSize: 30),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: pro,
          builder: (context, _) => pro.isPro
              ? _ProHub(onCancel: pro.restoreToFree)
              : _Paywall(onGoPro: pro.goPro),
        ),
      ),
    );
  }
}

// ── Paywall (free tier) ──────────────────────────────────────────────────

class _Paywall extends StatelessWidget {
  final Future<void> Function() onGoPro;

  const _Paywall({required this.onGoPro});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.darkPanel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TERRABITE',
                style: AppTextStyles.eyebrow.copyWith(color: AppColors.lime),
              ),
              const SizedBox(height: 4),
              Text(
                'Pro',
                style: AppTextStyles.hero.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: 60,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock the fine-dining world — Michelin-star recipes and '
                'a kit of pro cooking tools.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textOnDark.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (final feature in kProSections) ...[
          _FeatureRow(
            icon: feature.icon,
            title: feature.title,
            subtitle: feature.subtitle,
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onGoPro,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.textOnDark,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: Text(
              'Go Pro',
              style: AppTextStyles.button.copyWith(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Test build — no payment, instant unlock.',
            style: AppTextStyles.label,
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, size: 22, color: AppColors.orange),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.subheading),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Pro hub (unlocked) ───────────────────────────────────────────────────

class _ProHub extends StatelessWidget {
  final Future<void> Function() onCancel;

  const _ProHub({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: AppTheme.darkPanel,
          child: Row(
            children: [
              Icon(Icons.star_rounded, color: AppColors.lime, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You're Pro",
                      style: AppTextStyles.subheading.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Full access to the fine-dining collection and tools.',
                      style: AppTextStyles.bodyMuted.copyWith(
                        color: AppColors.textOnDark.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Sections', style: AppTextStyles.eyebrow),
        const SizedBox(height: 12),
        for (final section in kProSections) ...[
          _SectionCard(
            icon: section.icon,
            title: section.title,
            subtitle: section.subtitle,
            onTap: section.route == null
                ? null
                : () => context.push(section.route!),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        Text('Subscription', style: AppTextStyles.eyebrow),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: AppTheme.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TerraBite Pro — active', style: AppTextStyles.subheading),
              const SizedBox(height: 2),
              Text(
                'Test subscription. Cancelling returns you to the free tier.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger, width: 1.5),
                  ),
                  child: const Text('Cancel subscription'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Tap handler — `null` means the section is not built yet.
  final VoidCallback? onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: AppTheme.card,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, size: 22, color: AppColors.orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.subheading),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (available)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.muted,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSunk,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'SOON',
                    style: AppTextStyles.tag.copyWith(color: AppColors.muted),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pro sections (shared by the paywall list and the hub) ────────────────

class ProSection {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Route to open, or `null` if the section is not built yet.
  final String? route;

  const ProSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.route,
  });
}

const List<ProSection> kProSections = [
  ProSection(
    icon: Icons.star_rounded,
    title: 'Michelin Collection',
    subtitle: 'Signature dishes from the world’s best chefs.',
    route: '/pro/collection',
  ),
  ProSection(
    icon: Icons.person_rounded,
    title: 'Chef Spotlights',
    subtitle: 'Recipes grouped by legendary chefs.',
  ),
  ProSection(
    icon: Icons.local_fire_department_rounded,
    title: 'Cooking Mode',
    subtitle: 'Full-screen, step-by-step, screen stays awake.',
  ),
  ProSection(
    icon: Icons.restaurant_menu_rounded,
    title: 'Tasting-Menu Builder',
    subtitle: 'Compose a multi-course menu for a dinner party.',
  ),
  ProSection(
    icon: Icons.calendar_month_rounded,
    title: 'Meal Planner',
    subtitle: 'Plan your recipes across the week.',
  ),
  ProSection(
    icon: Icons.menu_book_rounded,
    title: 'My Cookbook Export',
    subtitle: 'Export your favorites as a printable PDF.',
  ),
];
