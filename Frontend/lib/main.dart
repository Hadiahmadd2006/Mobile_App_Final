import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'routing/app_router.dart';
import 'services/auth_repository.dart';
import 'services/favorites_repository.dart';
import 'services/in_memory_favorites_repository.dart';
import 'services/meal_api_service.dart';
import 'services/pro_controller.dart';
import 'services/recently_viewed_repository.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final api = MealApiService();
    final FavoritesRepository favorites = kIsWeb
        ? InMemoryFavoritesRepository()
        : SqfliteFavoritesRepository();
    final recentlyViewed = RecentlyViewedRepository();
    final auth = AuthRepository();
    final pro = ProController();
    await favorites.init().timeout(const Duration(seconds: 15));
    await recentlyViewed.init();
    await auth.init();
    pro.bindAuth(auth);
    await pro.load();
    runApp(
      TerraBiteApp(
        api: api,
        favorites: favorites,
        recentlyViewed: recentlyViewed,
        pro: pro,
        auth: auth,
      ),
    );
  } catch (error, stack) {
    debugPrint('TerraBite startup failed: $error\n$stack');
    runApp(StartupErrorApp(error: '$error', stack: '$stack'));
  }
}

class TerraBiteApp extends StatefulWidget {
  final MealApiService api;
  final FavoritesRepository favorites;
  final RecentlyViewedRepository recentlyViewed;
  final ProController pro;
  final AuthRepository auth;

  const TerraBiteApp({
    super.key,
    required this.api,
    required this.favorites,
    required this.recentlyViewed,
    required this.pro,
    required this.auth,
  });

  @override
  State<TerraBiteApp> createState() => _TerraBiteAppState();
}

class _TerraBiteAppState extends State<TerraBiteApp>
    with WidgetsBindingObserver {
  // Created once so navigation state survives dark/light rebuilds.
  late final _router = AppRouter.build(auth: widget.auth);

  @override
  void initState() {
    super.initState();
    AppColors.brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    final next = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (next != AppColors.brightness) {
      setState(() => AppColors.brightness = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: widget.api,
      favorites: widget.favorites,
      recentlyViewed: widget.recentlyViewed,
      pro: widget.pro,
      auth: widget.auth,
      child: MaterialApp.router(
        title: 'TerraBite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        routerConfig: _router,
      ),
    );
  }
}

/// Shown when startup fails before the app can render. Deliberately uses no
/// custom fonts or theme so it renders even if those are the cause.
class StartupErrorApp extends StatelessWidget {
  final String error;
  final String stack;

  const StartupErrorApp({super.key, required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const Text(
                  'Startup failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB23A1F),
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  error,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A1208),
                  ),
                ),
                const SizedBox(height: 20),
                SelectableText(
                  stack,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5A4A30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
