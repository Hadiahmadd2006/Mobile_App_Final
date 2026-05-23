import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../models/user.dart';
import '../../services/auth_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart';

/// Admin Create-or-Edit user screen.
///
/// When [userId] is null the form acts as Create. Otherwise it loads the
/// user, lets the admin update name, email, role, plan, and optionally
/// reset the password, and writes the row back through [AuthRepository].
class AdminEditUserScreen extends StatefulWidget {
  /// `null` → create a new user. Otherwise → edit the user with this id.
  final String? userId;

  const AdminEditUserScreen({super.key, this.userId});

  @override
  State<AdminEditUserScreen> createState() => _AdminEditUserScreenState();
}

class _AdminEditUserScreenState extends State<AdminEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  UserRole _role = UserRole.user;
  UserPlan _plan = UserPlan.free;
  bool _obscure = true;
  bool _submitting = false;
  bool _loading = true;
  String? _error;

  bool get _isEdit => widget.userId != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadIfNeeded);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadIfNeeded() async {
    if (!_isEdit) {
      setState(() => _loading = false);
      return;
    }
    try {
      final auth = AppScope.of(context).auth;
      final all = await auth.getAllUsers();
      final me = all.firstWhere((u) => u.id == widget.userId);
      _name.text = me.displayName;
      _email.text = me.email;
      _role = me.role;
      _plan = me.plan;
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Couldn\'t load user.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final auth = AppScope.of(context).auth;
    try {
      if (_isEdit) {
        await auth.adminUpdateUser(
          id: widget.userId!,
          email: _email.text,
          displayName: _name.text,
          role: _role,
          plan: _plan,
          newPassword:
              _password.text.isEmpty ? null : _password.text,
        );
      } else {
        await auth.adminCreateUser(
          email: _email.text,
          displayName: _name.text,
          password: _password.text,
          role: _role,
          plan: _plan,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'User updated.' : 'User created.')),
      );
      context.pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Save failed. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AuthScaffold(
      showBack: true,
      eyebrow: _isEdit ? 'EDIT USER' : 'NEW USER',
      title: _isEdit ? 'Update account' : 'Create account',
      subtitle: _isEdit
          ? 'Adjust profile, role, or plan. Leave password blank to keep it.'
          : 'Add a new TerraBite member. They can sign in immediately.',
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              AuthErrorBanner(_error!),
              const SizedBox(height: AppTheme.spaceMd),
            ],
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.length < 2) return 'At least 2 characters';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMd),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Required';
                if (!s.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceMd),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: _isEdit
                    ? 'New password (leave blank to keep)'
                    : 'Password',
                helperText: 'At least 6 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (_isEdit && (v == null || v.isEmpty)) return null;
                if (v == null || v.length < 6) {
                  return 'At least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text('ROLE', style: AppTextStyles.label),
            const SizedBox(height: 6),
            SegmentedButton<UserRole>(
              segments: const [
                ButtonSegment(
                  value: UserRole.user,
                  label: Text('User'),
                  icon: Icon(Icons.person_outline_rounded),
                ),
                ButtonSegment(
                  value: UserRole.admin,
                  label: Text('Admin'),
                  icon: Icon(Icons.shield_outlined),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text('PLAN', style: AppTextStyles.label),
            const SizedBox(height: 6),
            SegmentedButton<UserPlan>(
              segments: const [
                ButtonSegment(
                  value: UserPlan.free,
                  label: Text('Free'),
                ),
                ButtonSegment(
                  value: UserPlan.pro,
                  label: Text('Pro'),
                  icon: Icon(Icons.star_outline_rounded),
                ),
              ],
              selected: {_plan},
              onSelectionChanged: (s) => setState(() => _plan = s.first),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(_isEdit ? 'SAVE CHANGES' : 'CREATE USER'),
            ),
          ],
        ),
      ),
    );
  }
}

