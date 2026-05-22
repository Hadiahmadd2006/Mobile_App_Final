import 'package:flutter/widgets.dart';

import 'services/favorites_repository.dart';
import 'services/meal_api_service.dart';
import 'services/pro_controller.dart';
import 'services/recently_viewed_repository.dart';

class AppScope extends InheritedWidget {
  final MealApiService api;
  final FavoritesRepository favorites;
  final RecentlyViewedRepository recentlyViewed;
  final ProController pro;

  const AppScope({
    super.key,
    required this.api,
    required this.favorites,
    required this.recentlyViewed,
    required this.pro,
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
      pro != oldWidget.pro;
}
