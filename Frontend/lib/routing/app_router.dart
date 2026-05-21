import 'package:go_router/go_router.dart';

import '../models/meal.dart';
import '../screens/category_meals_screen.dart';
import '../screens/cuisine_meals_screen.dart';
import '../screens/edit_note_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_shell.dart';
import '../screens/meal_detail_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/recently_viewed_screen.dart';
import '../screens/search_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String home = '/home';
  static const String search = '/search';
  static const String recent = '/recent';
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
          builder: (context, state) => SplashScreen(),
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
                  builder: (context, state) => HomeScreen(),
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
                    GoRoute(
                      path: 'cuisine/:area',
                      name: 'cuisine',
                      builder: (context, state) {
                        final area = state.pathParameters['area'] ?? '';
                        return CuisineMealsScreen(area: area);
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
                  builder: (context, state) => SearchScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.recent,
                  name: 'recent',
                  builder: (context, state) => RecentlyViewedScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.favorites,
                  name: 'favorites',
                  builder: (context, state) => FavoritesScreen(),
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
