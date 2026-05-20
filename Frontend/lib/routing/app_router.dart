import 'package:go_router/go_router.dart';

import '../models/meal.dart';
import '../screens/category_meals_screen.dart';
import '../screens/edit_note_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_shell.dart';
import '../screens/meal_detail_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/search_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/home';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String categoryById = '/category/:id';
  static const String detailById = '/detail/:id';
  static const String editNoteById = '/edit-note/:id';
}

class AppRouter {
  AppRouter._();

  static GoRouter build() {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      errorBuilder: (context, state) =>
          NotFoundScreen(location: state.uri.toString()),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  name: 'home',
                  builder: (context, state) => const HomeScreen(),
                  routes: [
                    GoRoute(
                      path: 'category/:id',
                      name: 'category',
                      builder: (context, state) {
                        final id = state.pathParameters['id'] ?? '';
                        final name = state.uri.queryParameters['name'] ?? id;
                        return CategoryMealsScreen(
                          categoryId: id,
                          categoryName: name,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.search,
                  name: 'search',
                  builder: (context, state) => const SearchScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.favorites,
                  name: 'favorites',
                  builder: (context, state) => const FavoritesScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.detailById,
          name: 'detail',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            final preview = state.extra is Meal ? state.extra as Meal : null;
            return MealDetailScreen(mealId: id, preview: preview);
          },
        ),
        GoRoute(
          path: AppRoutes.editNoteById,
          name: 'editNote',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return EditNoteScreen(mealId: id);
          },
        ),
      ],
    );
  }
}
