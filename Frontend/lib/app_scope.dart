import 'package:flutter/widgets.dart';

import 'services/auth_repository.dart';
import 'services/favorites_repository.dart';
import 'services/meal_api_service.dart';
import 'services/meal_plan_repository.dart';
import 'services/pro_controller.dart';
import 'services/recently_viewed_repository.dart';
import 'services/settings_controller.dart';

class AppScope extends InheritedWidget {
  final MealApiService api;
  final FavoritesRepository favorites;
  final RecentlyViewedRepository recentlyViewed;
  final MealPlanRepository mealPlan;
  final ProController pro;
  final AuthRepository auth;
  final SettingsController settings;

  const AppScope({
    super.key,
    required this.api,
    required this.favorites,
    required this.recentlyViewed,
    required this.mealPlan,
    required this.pro,
    required this.auth,
    required this.settings,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      api != oldWidget.api ||
      favorites != oldWidget.favorites ||
      recentlyViewed != oldWidget.recentlyViewed ||
      mealPlan != oldWidget.mealPlan ||
      pro != oldWidget.pro ||
      auth != oldWidget.auth ||
      settings != oldWidget.settings;
}
