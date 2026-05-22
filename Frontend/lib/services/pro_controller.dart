import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the (test) Pro-subscription entitlement.
///
/// No real in-app purchase — the in-app "Go Pro" button simply flips this
/// flag. It is persisted locally so the Pro state survives app restarts,
/// and can be reset back to free for testing.
class ProController extends ChangeNotifier {
  static const String _key = 'terrabite_is_pro';

  bool _isPro = false;
  bool get isPro => _isPro;

  /// Loads the persisted entitlement. Best-effort — defaults to free.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPro = prefs.getBool(_key) ?? false;
    } catch (_) {
      _isPro = false;
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, _isPro);
    } catch (_) {
      // Best-effort — never disrupt the app over a test flag.
    }
  }

  Future<void> goPro() async {
    if (_isPro) return;
    _isPro = true;
    notifyListeners();
    await _persist();
  }

  Future<void> restoreToFree() async {
    if (!_isPro) return;
    _isPro = false;
    notifyListeners();
    await _persist();
  }
}
