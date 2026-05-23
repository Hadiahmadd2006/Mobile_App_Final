import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../models/user.dart';

/// Thrown by [AuthRepository] for known, user-friendly failures (bad
/// credentials, taken email, etc.). The message is safe to show in a
/// snackbar or inline error widget.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Local accounts + session for TerraBite.
///
/// Mirrors the patterns already used by [SqfliteFavoritesRepository] — same
/// `terrabite.db` file, same desktop/mobile factory split. Adds a `users`
/// table and stores the currently-signed-in user id in SharedPreferences so
/// the session survives restarts.
///
/// Passwords are stored as `sha256(salt + plaintext)`. Salt is 16 random
/// bytes encoded as base64 per user. This is not the same as bcrypt/argon2
/// but it is the standard local-only approach for a class project and is
/// noticeably better than plaintext.
class AuthRepository extends ChangeNotifier {
  static const String _table = 'users';
  static const int _version = 1;
  static const String _sessionKey = 'terrabite_session_user_id';

  Database? _db;
  AppUser? _currentUser;

  /// The currently signed-in user, or `null` for "no session".
  AppUser? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isPro => _currentUser?.isPro ?? false;

  // ── Lifecycle ───────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_db != null) return;

    DatabaseFactory factory;
    String path;

    if (kIsWeb) {
      throw UnsupportedError(
        'sqflite does not support web. Run on macOS, iOS, Android, or desktop.',
      );
    }

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      ffi.sqfliteFfiInit();
      factory = ffi.databaseFactoryFfi;
      final dir = await getApplicationSupportDirectory();
      path = p.join(dir.path, 'terrabite_users.db');
    } else {
      factory = databaseFactory;
      final dir = await getDatabasesPath();
      path = p.join(dir, 'terrabite_users.db');
    }

    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: (db, version) async {
          await _createUsersTable(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // The favorites repo may have created the database at v1 without
          // our table. Add it on the upgrade path so existing installs work.
          await _createUsersTable(db);
        },
        onOpen: (db) async {
          // Belt-and-braces: if both repos point at the same version on a
          // fresh DB and the other one opens first, neither onCreate nor
          // onUpgrade runs for us. Make sure the table exists.
          await _createUsersTable(db);
        },
      ),
    );

    await _ensureSeedAdmin();
    await _restoreSession();
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        displayName TEXT NOT NULL,
        role TEXT NOT NULL,
        plan TEXT NOT NULL,
        passwordHash TEXT NOT NULL,
        salt TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  /// Seeds a default admin account on first launch so the Admin Dashboard
  /// is reachable without first creating a user manually.
  ///
  /// Default credentials (advertised in the README/login screen):
  ///   email:    admin@terrabite.app
  ///   password: admin123
  ///
  /// Anyone can sign in with these on a fresh install — change them from
  /// the dashboard, or delete the row, before deploying anywhere real.
  Future<void> _ensureSeedAdmin() async {
    final db = _db!;
    final rows = await db.query(_table, limit: 1);
    if (rows.isNotEmpty) return;
    final user = _buildUser(
      email: 'admin@terrabite.app',
      displayName: 'TerraBite Admin',
      password: 'admin123',
      role: UserRole.admin,
      plan: UserPlan.pro,
    );
    await db.insert(_table, user.toRow());
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_sessionKey);
      if (id == null) return;
      final rows =
          await _db!.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isNotEmpty) {
        _currentUser = AppUser.fromRow(rows.first);
      }
    } catch (_) {
      // Best-effort — never block startup over a missing session.
    }
  }

  // ── Auth actions ────────────────────────────────────────────────────────

  Future<AppUser> signUp({
    required String email,
    required String displayName,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = displayName.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw const AuthException('Please enter a valid email address.');
    }
    if (cleanName.length < 2) {
      throw const AuthException('Display name must be at least 2 characters.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }

    final exists = await _db!.query(
      _table,
      where: 'email = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );
    if (exists.isNotEmpty) {
      throw const AuthException('An account with that email already exists.');
    }

    final user = _buildUser(
      email: cleanEmail,
      displayName: cleanName,
      password: password,
      role: UserRole.user,
      plan: UserPlan.free,
    );
    await _db!.insert(_table, user.toRow());
    await _setSession(user);
    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final rows = await _db!.query(
      _table,
      where: 'email = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const AuthException('No account found with that email.');
    }
    final user = AppUser.fromRow(rows.first);
    final candidate = _hash(password, user.salt);
    if (candidate != user.passwordHash) {
      throw const AuthException('Incorrect password.');
    }
    await _setSession(user);
    return user;
  }

  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (_) {/* ignored */}
  }

  Future<void> _setSession(AppUser user) async {
    _currentUser = user;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, user.id);
    } catch (_) {/* ignored */}
  }

  // ── Admin CRUD ──────────────────────────────────────────────────────────

  Future<List<AppUser>> getAllUsers() async {
    final rows = await _db!.query(_table, orderBy: 'createdAt DESC');
    return rows.map(AppUser.fromRow).toList(growable: false);
  }

  /// Returns simple counts for the dashboard header.
  Future<Map<String, int>> getCounts() async {
    final users = await getAllUsers();
    return {
      'total': users.length,
      'admins': users.where((u) => u.isAdmin).length,
      'pro': users.where((u) => u.isPro).length,
      'free': users.where((u) => !u.isPro).length,
    };
  }

  /// Admin: create a new user manually. Behaves like [signUp] but does not
  /// touch the current session and lets the caller pick role + plan.
  Future<AppUser> adminCreateUser({
    required String email,
    required String displayName,
    required String password,
    required UserRole role,
    required UserPlan plan,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = displayName.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw const AuthException('Please enter a valid email address.');
    }
    if (cleanName.length < 2) {
      throw const AuthException('Display name must be at least 2 characters.');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters.');
    }
    final exists = await _db!.query(
      _table,
      where: 'email = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );
    if (exists.isNotEmpty) {
      throw const AuthException('An account with that email already exists.');
    }
    final user = _buildUser(
      email: cleanEmail,
      displayName: cleanName,
      password: password,
      role: role,
      plan: plan,
    );
    await _db!.insert(_table, user.toRow());
    notifyListeners();
    return user;
  }

  /// Admin: update profile fields, role, plan, and optionally reset password.
  /// Pass `newPassword: null` to keep the existing password.
  Future<AppUser> adminUpdateUser({
    required String id,
    required String email,
    required String displayName,
    required UserRole role,
    required UserPlan plan,
    String? newPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = displayName.trim();

    final rows = await _db!.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      throw const AuthException('User not found.');
    }
    final existing = AppUser.fromRow(rows.first);

    // Block taken-by-other-user emails.
    final dup = await _db!.query(
      _table,
      where: 'email = ? AND id != ?',
      whereArgs: [cleanEmail, id],
      limit: 1,
    );
    if (dup.isNotEmpty) {
      throw const AuthException('Another account already uses that email.');
    }

    String passwordHash = existing.passwordHash;
    String salt = existing.salt;
    if (newPassword != null && newPassword.isNotEmpty) {
      if (newPassword.length < 6) {
        throw const AuthException('Password must be at least 6 characters.');
      }
      salt = _generateSalt();
      passwordHash = _hash(newPassword, salt);
    }

    final updated = existing.copyWith(
      email: cleanEmail,
      displayName: cleanName,
      role: role,
      plan: plan,
      passwordHash: passwordHash,
      salt: salt,
    );
    await _db!.update(_table, updated.toRow(), where: 'id = ?', whereArgs: [id]);

    // If the admin just modified their own session, refresh it in memory.
    if (_currentUser?.id == id) {
      _currentUser = updated;
    }
    notifyListeners();
    return updated;
  }

  /// Admin: delete a user. Refuses to delete the last remaining admin so
  /// the dashboard can never lock everyone out.
  Future<void> adminDeleteUser(String id) async {
    final all = await getAllUsers();
    final victim = all.firstWhere((u) => u.id == id,
        orElse: () => throw const AuthException('User not found.'));
    if (victim.isAdmin) {
      final admins = all.where((u) => u.isAdmin).length;
      if (admins <= 1) {
        throw const AuthException(
          'You cannot delete the last admin. Promote another user first.',
        );
      }
    }
    await _db!.delete(_table, where: 'id = ?', whereArgs: [id]);
    // Sign out if the deleted user was the one logged in.
    if (_currentUser?.id == id) {
      await signOut();
    } else {
      notifyListeners();
    }
  }

  /// Convenience for the Pro tab: upgrade the current user to Pro.
  Future<void> upgradeCurrentToPro() async {
    final me = _currentUser;
    if (me == null || me.isPro) return;
    final updated = me.copyWith(plan: UserPlan.pro);
    await _db!.update(_table, updated.toRow(),
        where: 'id = ?', whereArgs: [me.id]);
    _currentUser = updated;
    notifyListeners();
  }

  Future<void> downgradeCurrentToFree() async {
    final me = _currentUser;
    if (me == null || !me.isPro) return;
    final updated = me.copyWith(plan: UserPlan.free);
    await _db!.update(_table, updated.toRow(),
        where: 'id = ?', whereArgs: [me.id]);
    _currentUser = updated;
    notifyListeners();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  AppUser _buildUser({
    required String email,
    required String displayName,
    required String password,
    required UserRole role,
    required UserPlan plan,
  }) {
    final salt = _generateSalt();
    return AppUser(
      id: _generateId(),
      email: email,
      displayName: displayName,
      role: role,
      plan: plan,
      passwordHash: _hash(password, salt),
      salt: salt,
      createdAt: DateTime.now(),
    );
  }

  String _generateId() {
    final rng = Random.secure();
    final bytes = List<int>.generate(12, (_) => rng.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64.encode(bytes);
  }

  String _hash(String password, String salt) {
    final bytes = utf8.encode('$salt$password');
    return sha256.convert(bytes).toString();
  }
}
