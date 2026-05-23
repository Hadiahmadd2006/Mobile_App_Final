import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_repository.dart';

/// Bridges the existing `pro.isPro` API onto the per-user plan stored in
/// [AuthRepository]. Every existing call site (Pro tab, paywall card,
/// Michelin gates) keeps working without changes — the source of truth has
/// moved from a single SharedPreferences flag to the signed-in user's
/// row in the local database.
///
/// One UI flag still lives in SharedPreferences globally: [seenIntro],
/// which gates the first-time celebratory Pro intro modal. It is sticky
/// and device-wide rather than per-user, because we want to avoid
/// re-showing the teaser to anyone who has already seen it on this phone.
class ProController extends ChangeNotifier {
  static const String _keySeenIntro = 'terrabite_pro_intro_seen';

  AuthRepository? _auth;

  bool _seenIntro = false;
  bool get seenIntro => _seenIntro;

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

  /// Loads the persisted intro flag. Plan state lives on the auth user row
  /// so there's nothing else to load here.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seenIntro = prefs.getBool(_keySeenIntro) ?? false;
    } catch (_) {
      _seenIntro = false;
    }
    notifyListeners();
  }

  Future<void> markIntroSeen() async {
    if (_seenIntro) return;
    _seenIntro = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySeenIntro, true);
    } catch (_) {
      // Best-effort — never disrupt the app over a test flag.
    }
  }

  Future<void> goPro() async {
    await _auth?.upgradeCurrentToPro();
  }

  Future<void> restoreToFree() async {
    await _auth?.downgradeCurrentToFree();
  }
}
