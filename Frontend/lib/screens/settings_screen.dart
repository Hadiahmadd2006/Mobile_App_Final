import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_scope.dart';
import '../models/user.dart';
import '../routing/app_router.dart';
import '../services/auth_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Self-service Settings — profile editing, theme override, subscription
/// link, about, and the destructive sign-out / delete-account actions.
///
/// Routed at `/settings`, opened from the side drawer. The screen is
/// rebuilt automatically whenever the signed-in user changes or the
/// theme override flips.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    MediaQuery.platformBrightnessOf(context);
    final scope = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        title: Text(
          'Settings',
          style: AppTextStyles.heading.copyWith(fontSize: 26),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([scope.auth, scope.settings, scope.pro]),
        builder: (context, _) {
          final user = scope.auth.currentUser;
          if (user == null) {
            // Auth redirect should prevent this, but be defensive.
            return Center(
              child: Text('Not signed in.', style: AppTextStyles.body),
            );
          }
          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _ProfileCard(user: user),
                const SizedBox(height: 24),
                _SectionHeader(label: 'Account'),
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit profile',
                  subtitle: 'Display name and email',
                  onTap: () => _openEditProfile(context, user),
                ),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change password',
                  subtitle: 'Update your sign-in password',
                  onTap: () => _openChangePassword(context),
                ),
                const SizedBox(height: 18),
                _SectionHeader(label: 'Appearance'),
                _ThemeTile(
                  current: scope.settings.themeMode,
                  onChanged: (mode) => scope.settings.setThemeMode(mode),
                ),
                const SizedBox(height: 18),
                _SectionHeader(label: 'Subscription'),
                _SettingsTile(
                  icon: user.isPro
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  title: user.isPro ? 'TerraBite Pro — active' : 'Go Pro',
                  subtitle: user.isPro
                      ? 'Manage your subscription'
                      : 'Unlock Michelin, Cooking Mode, Meal Planner, and more',
                  trailing: user.isPro
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            'PRO',
                            style: AppTextStyles.tag.copyWith(
                              color: AppColors.inkFixed,
                              letterSpacing: 1.4,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => context.go('/pro'),
                ),
                const SizedBox(height: 18),
                _SectionHeader(label: 'About'),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About TerraBite',
                  subtitle: 'Version 1.0.0 · powered by TheMealDB',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'TerraBite',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'Recipes powered by TheMealDB. Built with Flutter.',
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'A warm, editorial recipe explorer — browse '
                          'categories, search dishes, and save personal '
                          'cooking notes for later.',
                          style: AppTextStyles.bodyMuted,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                _SectionHeader(label: 'Danger zone'),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.danger,
                  title: 'Sign out',
                  subtitle: 'Sign back in any time on the welcome screen',
                  destructive: true,
                  onTap: () => _signOut(context, scope.auth),
                ),
                _SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.danger,
                  title: 'Delete account',
                  subtitle: 'Permanently remove your account and history',
                  destructive: true,
                  onTap: () => _openDeleteAccount(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Action handlers ───────────────────────────────────────────────────

  Future<void> _signOut(BuildContext context, AuthRepository auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Sign out?',
        message: 'You can sign back in any time with the same email.',
        confirmLabel: 'Sign out',
        destructive: true,
      ),
    );
    if (confirmed != true) return;
    await auth.signOut();
    if (!context.mounted) return;
    context.go(AppRoutes.welcome);
  }

  Future<void> _openEditProfile(BuildContext context, AppUser user) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  Future<void> _openChangePassword(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _openDeleteAccount(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _DeleteAccountSheet(),
    );
  }
}

// ── Profile card (header) ─────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final AppUser user;

  const _ProfileCard({required this.user});

  String get _initials {
    final n = user.displayName.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.darkPanel,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials,
              style: AppTextStyles.heading.copyWith(
                color: AppColors.inkFixed,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: AppTextStyles.subheading.copyWith(
                    color: AppColors.textOnDark,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textOnDark.withValues(alpha: 0.75),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Chip(
                      label: user.isAdmin ? 'ADMIN' : 'USER',
                      color: user.isAdmin ? AppColors.orange : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    _Chip(
                      label: user.isPro ? 'PRO' : 'FREE',
                      color: user.isPro ? AppColors.lime : AppColors.muted,
                      textColor:
                          user.isPro ? AppColors.inkFixed : AppColors.textOnDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const _Chip({required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: AppTextStyles.tag.copyWith(
          color: textColor ?? AppColors.textOnDark,
          letterSpacing: 1.4,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ── Section header & tile ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.eyebrow.copyWith(color: AppColors.muted),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool destructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor,
    this.trailing,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.card,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.orange)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.subheading.copyWith(
                          fontSize: 15,
                          color: destructive
                              ? AppColors.danger
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.muted,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Theme tile ────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeTile({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    size: 20,
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: AppTextStyles.subheading
                            .copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'How TerraBite looks across the app',
                        style: AppTextStyles.label,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ThemePill(
                    label: 'System',
                    selected: current == ThemeMode.system,
                    onTap: () => onChanged(ThemeMode.system),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ThemePill(
                    label: 'Light',
                    selected: current == ThemeMode.light,
                    onTap: () => onChanged(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ThemePill(
                    label: 'Dark',
                    selected: current == ThemeMode.dark,
                    onTap: () => onChanged(ThemeMode.dark),
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

class _ThemePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.orange : AppColors.surfaceSunk,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: selected ? AppColors.orange : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.subheading.copyWith(
              color: selected ? AppColors.textOnDark : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Confirm dialog (shared) ───────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.subheading.copyWith(fontSize: 18)),
            const SizedBox(height: 10),
            Text(message, style: AppTextStyles.body),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          destructive ? AppColors.danger : AppColors.orange,
                      foregroundColor: AppColors.textOnDark,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(confirmLabel),
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

// ── Edit profile sheet ────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final AppUser user;

  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.displayName);
    _email = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = AppScope.of(context).auth;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await auth.updateCurrentProfile(
        displayName: _name.text,
        email: _email.text,
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
      navigator.pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _Sheet(
        title: 'Edit profile',
        children: [
          Text('DISPLAY NAME', style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          const SizedBox(height: 14),
          Text('EMAIL', style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          ),
          const SizedBox(height: 18),
          _SheetActions(busy: _busy, onSave: _save),
        ],
      ),
    );
  }
}

// ── Change-password sheet ─────────────────────────────────────────────

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = AppScope.of(context).auth;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_next.text != _confirm.text) {
      messenger.showSnackBar(
        const SnackBar(content: Text("New passwords don't match.")),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await auth.changeCurrentPassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Password changed.')));
      navigator.pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _Sheet(
        title: 'Change password',
        children: [
          Text('CURRENT PASSWORD', style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          TextField(
            controller: _current,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Current password'),
          ),
          const SizedBox(height: 14),
          Text('NEW PASSWORD', style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          TextField(
            controller: _next,
            obscureText: true,
            decoration:
                const InputDecoration(hintText: 'At least 6 characters'),
          ),
          const SizedBox(height: 14),
          Text('CONFIRM NEW PASSWORD', style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Repeat new password'),
          ),
          const SizedBox(height: 18),
          _SheetActions(busy: _busy, onSave: _save, saveLabel: 'Update'),
        ],
      ),
    );
  }
}

// ── Delete-account sheet ──────────────────────────────────────────────

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet();

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final auth = AppScope.of(context).auth;
    final messenger = ScaffoldMessenger.of(context);
    final goRouter = GoRouter.of(context);
    setState(() => _busy = true);
    try {
      await auth.deleteCurrentAccount(password: _password.text);
      if (!mounted) return;
      goRouter.go(AppRoutes.welcome);
      messenger.showSnackBar(
        const SnackBar(content: Text('Account deleted.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _Sheet(
        title: 'Delete account',
        accent: AppColors.danger,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is permanent. Your account, notes, and Pro status '
                    'will be removed. Enter your password to confirm.',
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('PASSWORD', style: AppTextStyles.eyebrow),
          const SizedBox(height: 6),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Your password'),
          ),
          const SizedBox(height: 18),
          _SheetActions(
            busy: _busy,
            onSave: _delete,
            saveLabel: 'Delete account',
            destructive: true,
          ),
        ],
      ),
    );
  }
}

// ── Sheet chrome (shared) ─────────────────────────────────────────────

class _Sheet extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color? accent;

  const _Sheet({required this.title, required this.children, this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 22,
                    color: accent ?? AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close_rounded, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _SheetActions extends StatelessWidget {
  final bool busy;
  final VoidCallback onSave;
  final String saveLabel;
  final bool destructive;

  const _SheetActions({
    required this.busy,
    required this.onSave,
    this.saveLabel = 'Save',
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: busy ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: busy ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  destructive ? AppColors.danger : AppColors.orange,
              foregroundColor: AppColors.textOnDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.textOnDark),
                    ),
                  )
                : Text(saveLabel),
          ),
        ),
      ],
    );
  }
}
