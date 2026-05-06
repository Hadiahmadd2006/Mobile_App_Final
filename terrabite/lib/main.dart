import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'routing/app_router.dart';
import 'services/favorites_repository.dart';
import 'services/in_memory_favorites_repository.dart';
import 'services/meal_api_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = MealApiService();
  final FavoritesRepository favorites = kIsWeb
      ? InMemoryFavoritesRepository()
      : SqfliteFavoritesRepository();
  await favorites.init();

  runApp(TerraBiteApp(api: api, favorites: favorites));
}

class TerraBiteApp extends StatelessWidget {
  final MealApiService api;
  final FavoritesRepository favorites;

  const TerraBiteApp({
    super.key,
    required this.api,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: api,
      favorites: favorites,
      child: MaterialApp.router(
        title: 'TerraBite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        routerConfig: AppRouter.build(),
      ),
    );
  }
}
