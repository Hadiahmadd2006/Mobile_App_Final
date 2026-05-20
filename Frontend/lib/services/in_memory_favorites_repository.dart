import 'dart:async';

import '../models/favorite_meal.dart';
import 'favorites_repository.dart';

class InMemoryFavoritesRepository implements FavoritesRepository {
  final Map<String, FavoriteMeal> _store = {};
  final StreamController<List<FavoriteMeal>> _controller =
      StreamController<List<FavoriteMeal>>.broadcast();

  @override
  Future<void> init() async {
    _emit();
  }

  @override
  Future<List<FavoriteMeal>> getAllFavorites() async {
    final list = _store.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return list;
  }

  @override
  Future<FavoriteMeal?> getById(String id) async => _store[id];

  @override
  Future<bool> isFavorite(String id) async => _store.containsKey(id);

  @override
  Future<void> saveMeal(FavoriteMeal meal) async {
    _store[meal.id] = meal;
    _emit();
  }

  @override
  Future<void> updateNote({
    required String id,
    required String noteTitle,
    required String noteBody,
  }) async {
    final existing = _store[id];
    if (existing == null) return;
    _store[id] = existing.copyWith(noteTitle: noteTitle, noteBody: noteBody);
    _emit();
  }

  @override
  Future<void> deleteMeal(String id) async {
    _store.remove(id);
    _emit();
  }

  @override
  Stream<List<FavoriteMeal>> watchFavorites() => _controller.stream;

  void _emit() {
    if (_controller.isClosed) return;
    final list = _store.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    _controller.add(list);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
