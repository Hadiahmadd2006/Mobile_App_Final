import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../models/user.dart';
import '../../routing/app_router.dart';
import '../../services/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_view.dart';

/// Admin-only screen: list every user, see counts at a glance, and run full
/// CRUD (Create / Read / Update / Delete) against the local users table.
///
/// Access is gated by the GoRouter redirect — non-admins are bounced back
/// to /home before this widget builds.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AuthRepository _auth;
  Future<_DashboardData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _auth = AppScope.of(context).auth;
    _future ??= _load();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  Future<_DashboardData> _load() async {
    final users = await _auth.getAllUsers();
    final counts = await _auth.getCounts();
    return _DashboardData(users: users, counts: counts);
  }

  Future<void> _confirmDelete(AppUser user) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          'Permanently delete "${user.displayName}" (${user.email}). '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('DELETE',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _auth.adminDeleteUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${user.displayName}.')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'Admin',
          style: AppTextStyles.heading.copyWith(fontSize: 24),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminNewUser),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('NEW USER'),
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<_DashboardData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const LoadingView();
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Couldn\'t load users: ${snap.error}',
                      style: AppTextStyles.body),
                ),
              );
            }
            final data = snap.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _future = _load());
                await _future;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceLg, AppTheme.spaceMd, AppTheme.spaceLg, 96),
                children: [
                  _CountsHeader(counts: data.counts),
                  const SizedBox(height: AppTheme.spaceLg),
                  Text('All accounts', style: AppTextStyles.heading),
                  const SizedBox(height: AppTheme.spaceSm),
                  ...data.users.map(
                    (u) => _UserCard(
                      user: u,
                      isSelf: u.id == _auth.currentUser?.id,
                      onEdit: () =>
                          context.push('${AppRoutes.adminBase}/edit/${u.id}'),
                      onDelete: () => _confirmDelete(u),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardData {
  final List<AppUser> users;
  final Map<String, int> counts;
  _DashboardData({required this.users, required this.counts});
}

class _CountsHeader extends StatelessWidget {
  final Map<String, int> counts;
  const _CountsHeader({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.darkPanel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ADMIN OVERVIEW',
              style: AppTextStyles.eyebrow
                  .copyWith(color: AppColors.lime)),
          const SizedBox(height: 6),
          Text(
            '${counts['total']} accounts',
            style: AppTextStyles.hero.copyWith(
              color: AppColors.textOnDark,
              fontSize: 44,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              _Stat(label: 'Admins', value: counts['admins'] ?? 0),
              const SizedBox(width: 18),
              _Stat(label: 'Pro', value: counts['pro'] ?? 0),
              const SizedBox(width: 18),
              _Stat(label: 'Free', value: counts['free'] ?? 0),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(
                color: AppColors.textOnDark.withValues(alpha: 0.7),
                fontSize: 11)),
        const SizedBox(height: 2),
        Text('$value',
            style: AppTextStyles.heading.copyWith(
                color: AppColors.textOnDark, fontSize: 22)),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: user.isAdmin
                    ? AppColors.espresso
                    : AppColors.orange.withValues(alpha: 0.18),
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName.characters.first.toUpperCase()
                      : '?',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 18,
                    color: user.isAdmin
                        ? AppColors.textOnDark
                        : AppColors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(user.displayName,
                              style: AppTextStyles.subheading,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('YOU',
                                style: AppTextStyles.tag.copyWith(
                                    color: AppColors.inkFixed,
                                    fontSize: 9)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(user.email,
                        style: AppTextStyles.bodyMuted
                            .copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Pill(
                label: user.isAdmin ? 'ADMIN' : 'USER',
                background: user.isAdmin
                    ? AppColors.espresso
                    : AppColors.surfaceSunk,
                foreground: user.isAdmin
                    ? AppColors.textOnDark
                    : AppColors.espresso,
              ),
              const SizedBox(width: 8),
              _Pill(
                label: user.isPro ? 'PRO' : 'FREE',
                background: user.isPro
                    ? AppColors.lime
                    : AppColors.surfaceSunk,
                foreground: user.isPro
                    ? AppColors.inkFixed
                    : AppColors.muted,
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined,
                    color: AppColors.espresso),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline,
                    color: AppColors.danger),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: AppTextStyles.tag
              .copyWith(color: foreground, fontSize: 10)),
    );
  }
}

