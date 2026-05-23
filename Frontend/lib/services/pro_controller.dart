import 'package:flutter/foundation.dart';

import 'auth_repository.dart';

/// Bridges the existing `pro.isPro` API onto the per-user plan stored in
/// [AuthRepository]. Every existing call site (Pro tab, paywall card,
/// Michelin gates) keeps working without changes — the source of truth has
/// just moved from a single SharedPreferences flag to the signed-in user's
/// row in the local database.
class ProController extends ChangeNotifier {
  AuthRepository? _auth;

  ProController();

  /// Connects this controller to the auth repo at startup. Called once
  /// from `main.dart` after both have been instantiated.
  void bindAuth(AuthRepository auth) {
    _auth = auth;
    _auth!.addListener(_onAuthChanged);
    notifyListeners();
  }

  void _onAuthChanged() => notifyListeners();

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// `true` once the signed-in user's plan is Pro. Anonymous (signed-out)
  /// visitors are treated as free.
  bool get isPro => _auth?.currentUser?.isPro ?? false;

  /// Kept for backwards compatibility with the old startup flow — the auth
  /// repo persists the plan, so there is nothing else to load here.
  Future<void> load() async {}

  Future<void> goPro() async {
    await _auth?.upgradeCurrentToPro();
  }

  Future<void> restoreToFree() async {
    await _auth?.downgradeCurrentToFree();
  }
}
