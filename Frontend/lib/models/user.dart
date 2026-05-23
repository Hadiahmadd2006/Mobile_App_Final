/// The user role.
///
/// `admin` users see the Admin Dashboard in the drawer and can manage every
/// account. `user` is the default role assigned to anyone signing up.
enum UserRole { admin, user }

/// The subscription plan.
///
/// Mirrors the existing `ProController` flag, but the source of truth now
/// lives on the user row so an admin can flip a member to Pro from the
/// dashboard.
enum UserPlan { free, pro }

UserRole _roleFromString(String s) =>
    s == 'admin' ? UserRole.admin : UserRole.user;

UserPlan _planFromString(String s) =>
    s == 'pro' ? UserPlan.pro : UserPlan.free;

/// A single row from the local `users` table.
///
/// `passwordHash` is the lowercase hex SHA-256 of `salt + plaintext` — see
/// [AuthRepository._hash]. `salt` is random per-user so identical passwords
/// produce different hashes.
class AppUser {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final UserPlan plan;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.plan,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isPro => plan == UserPlan.pro;

  AppUser copyWith({
    String? email,
    String? displayName,
    UserRole? role,
    UserPlan? plan,
    String? passwordHash,
    String? salt,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      plan: plan ?? this.plan,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toRow() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'role': role == UserRole.admin ? 'admin' : 'user',
    'plan': plan == UserPlan.pro ? 'pro' : 'free',
    'passwordHash': passwordHash,
    'salt': salt,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromRow(Map<String, Object?> row) => AppUser(
    id: row['id'] as String,
    email: row['email'] as String,
    displayName: row['displayName'] as String,
    role: _roleFromString(row['role'] as String),
    plan: _planFromString(row['plan'] as String),
    passwordHash: row['passwordHash'] as String,
    salt: row['salt'] as String,
    createdAt: DateTime.tryParse(row['createdAt'] as String? ?? '') ??
        DateTime.now(),
  );
}

