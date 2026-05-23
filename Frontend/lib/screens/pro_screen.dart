import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../app_scope.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'pro_intro_screen.dart';

/// The Pro tab: a paywall on the free tier, or the Pro hub once unlocked.
class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  bool _introScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowIntro();
  }

  /// First-time celebratory intro — shown once when a free user lands on
  /// the Pro tab. After dismissing they see the regular paywall.
  void _maybeShowIntro() {
    if (_introScheduled) return;
    _introScheduled = true;
    final pro = AppScope.of(context).pro;
    if (pro.isPro || pro.seenIntro) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const ProIntroScreen(),
        ),
      );
      if (!mounted) return;
      await pro.markIntroSeen();
    });
  }

  Future<void> _goProWithBiometrics() async {
    final pro = AppScope.of(context).pro;
    final messenger = ScaffoldMessenger.of(context);
    final auth = LocalAuthentication();

    // Try a biometric-only prompt first (Face ID / Touch ID). If the
    // device has no biometrics enrolled we fall back to the device
    // passcode, so the demo still completes on simulators or older
    // phones.
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Confirm your purchase of TerraBite Pro',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Couldn't run biometrics: $e")),
      );
      return;
    }

    if (!authenticated) return;
    if (!mounted) return;

    // Fake the payment processing beat so the unlock feels deliberate.
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Processing payment…'),
        duration: Duration(milliseconds: 800),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    await pro.goPro();
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Welcome to TerraBite Pro!')),
    );
  }

  Future<void> _cancelWithConfirm() async {
    final pro = AppScope.of(context).pro;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CancelDialog(),
    );
    if (confirmed == true) {
      await pro.restoreToFree();
    }
  }

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
              ? _ProHub(onCancel: _cancelWithConfirm)
              : _Paywall(onGoPro: _goProWithBiometrics),
        ),
      ),
    );
  }
}

/// Confirmation dialog shown when a Pro user taps "Cancel subscription".
class _CancelDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cancel subscription?',
                    style: AppTextStyles.subheading.copyWith(fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Are you sure you want to cancel your TerraBite Pro '
              'subscription? You\'ll lose access to Michelin recipes, '
              'Chef Spotlights, the Meal Planner, Cooking Mode, and the '
              'Cookbook PDF export.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('No'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.textOnDark,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Yes, cancel'),
                  ),
                ),
              ],
            ),
          ],
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
    route: '/pro/spotlights',
  ),
  ProSection(
    icon: Icons.local_fire_department_rounded,
    title: 'Cooking Mode',
    subtitle: 'Full-screen, step-by-step, screen stays awake.',
    route: '/pro/cook',
  ),
  ProSection(
    icon: Icons.calendar_month_rounded,
    title: 'Meal Planner',
    subtitle: 'Plan your recipes across the week.',
    route: '/pro/planner',
  ),
  ProSection(
    icon: Icons.menu_book_rounded,
    title: 'My Cookbook Export',
    subtitle: 'Export your favorites as a printable PDF.',
    route: '/pro/cookbook',
  ),
];
