import 'package:flutter/widgets.dart';

import 'services/favorites_repository.dart';
import 'services/meal_api_service.dart';

class AppScope extends InheritedWidget {
  final MealApiService api;
  final FavoritesRepository favorites;

  const AppScope({
    super.key,
    required this.api,
    required this.favorites,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      api != oldWidget.api || favorites != oldWidget.favorites;
}
