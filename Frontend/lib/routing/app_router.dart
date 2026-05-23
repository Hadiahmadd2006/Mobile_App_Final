import 'package:go_router/go_router.dart';

import '../models/meal.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_edit_user_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/category_meals_screen.dart';
import '../screens/chef_spotlights_screen.dart';
import '../screens/cookbook_export_screen.dart';
import '../screens/cooking_mode_launcher_screen.dart';
import '../screens/cuisine_meals_screen.dart';
import '../screens/edit_note_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_shell.dart';
import '../screens/meal_detail_screen.dart';
import '../screens/meal_planner_screen.dart';
import '../screens/michelin_collection_screen.dart';
import '../screens/michelin_recipe_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/pro_screen.dart';
import '../screens/recently_viewed_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../services/auth_repository.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';

  // Auth
  static const String welcome = '/welcome';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';

  // Tabs
  static const String home = '/home';
  static const String search = '/search';
  static const String recent = '/recent';
  static const String favorites = '/favorites';

  // Detail flows
  static const String categoryById = '/category/:id';
  static const String detailById = '/detail/:id';
  static const String editNoteById = '/edit-note/:id';

  // Admin
  static const String adminBase = '/admin';
  static const String adminNewUser = '/admin/new';

  // Settings
  static const String settings = '/settings';
}

class AppRouter {
  AppRouter._();

  /// Build the router with an auth repo attached so the redirect can read
  /// the session on every navigation and bounce unauthenticated users to
  /// the welcome page (and non-admins out of /admin).
  static GoRouter build({required AuthRepository auth}) {
    return GoRouter(
      initialLocation: AppRoutes.splash,
      // Re-runs the redirect whenever auth state changes (sign in / out).
      refreshListenable: auth,
      errorBuilder: (context, state) =>
          NotFoundScreen(location: state.uri.toString()),
      redirect: (context, state) {
        final loc = state.uri.path;
        final isAuthRoute = loc == AppRoutes.welcome ||
            loc == AppRoutes.signIn ||
            loc == AppRoutes.signUp;
        final isSplash = loc == AppRoutes.splash;

        // Splash always renders — it routes itself on completion.
        if (isSplash) return null;

        if (!auth.isSignedIn) {
          // Signed-out: only allow the auth pages.
          return isAuthRoute ? null : AppRoutes.welcome;
        }

        // Signed-in: keep them out of the auth pages.
        if (isAuthRoute) return AppRoutes.home;

        // Admin routes require admin role.
        if (loc.startsWith(AppRoutes.adminBase) && !auth.isAdmin) {
          return AppRoutes.home;
        }
        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.signIn,
          name: 'signIn',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.signUp,
          name: 'signUp',
          builder: (context, state) => const SignUpScreen(),
        ),
        // Admin routes — gated by redirect() above.
        GoRoute(
          path: AppRoutes.adminBase,
          name: 'admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.adminNewUser,
          name: 'adminNewUser',
          builder: (context, state) => const AdminEditUserScreen(),
        ),
        GoRoute(
          path: '/admin/edit/:id',
          name: 'adminEditUser',
          builder: (context, state) => AdminEditUserScreen(
            userId: state.pathParameters['id'],
          ),
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
                  path: '/pro',
                  name: 'pro',
                  builder: (context, state) => const ProScreen(),
                  routes: [
                    GoRoute(
                      path: 'collection',
                      name: 'michelinCollection',
                      builder: (context, state) =>
                          const MichelinCollectionScreen(),
                    ),
                    GoRoute(
                      path: 'spotlights',
                      name: 'chefSpotlights',
                      builder: (context, state) =>
                          const ChefSpotlightsScreen(),
                    ),
                    GoRoute(
                      path: 'cook',
                      name: 'cookingModeLauncher',
                      builder: (context, state) =>
                          const CookingModeLauncherScreen(),
                    ),
                    GoRoute(
                      path: 'planner',
                      name: 'mealPlanner',
                      builder: (context, state) => const MealPlannerScreen(),
                    ),
                    GoRoute(
                      path: 'cookbook',
                      name: 'cookbookExport',
                      builder: (context, state) =>
                          const CookbookExportScreen(),
                    ),
                    GoRoute(
                      path: 'recipe/:id',
                      name: 'michelinRecipe',
                      builder: (context, state) => MichelinRecipeScreen(
                        recipeId: state.pathParameters['id'] ?? '',
                      ),
                    ),
                  ],
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
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }
}
