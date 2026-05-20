import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meal.dart';
import '../models/meal_category.dart';
import '../models/meal_detail.dart';

class MealApiException implements Exception {
  final String message;
  const MealApiException(this.message);

  @override
  String toString() => 'MealApiException: $message';
}

class MealApiService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  static const Duration _timeout = Duration(seconds: 10);

  /// Categories hidden from the app (and filtered out of search results).
  static const Set<String> _excludedCategories = {'pork', 'vegetarian'};

  final http.Client _client;

  MealApiService({http.Client? client}) : _client = client ?? http.Client();

  bool _isExcludedCategory(String name) =>
      _excludedCategories.contains(name.trim().toLowerCase());

  Future<List<MealCategory>> fetchCategories() async {
    final uri = Uri.parse('$_baseUrl/categories.php');
    final body = await _getJson(uri);
    final list = body['categories'];
    if (list is! List) {
      throw const MealApiException('Unexpected categories payload.');
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(MealCategory.fromJson)
        .where((category) => !_isExcludedCategory(category.name))
        .toList();
  }

  Future<List<Meal>> fetchMealsByCategory(String category) async {
    final uri = Uri.parse('$_baseUrl/filter.php?c=$category');
    final body = await _getJson(uri);
    final list = body['meals'];
    if (list == null) return const [];
    if (list is! List) {
      throw const MealApiException('Unexpected meals payload.');
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(Meal.fromJson)
        .toList();
  }

  Future<List<Meal>> searchMealsByName(String query) async {
    final encoded = Uri.encodeQueryComponent(query);
    final uri = Uri.parse('$_baseUrl/search.php?s=$encoded');
    final body = await _getJson(uri);
    final list = body['meals'];
    if (list == null) return const [];
    if (list is! List) {
      throw const MealApiException('Unexpected search payload.');
    }
    return list
        .whereType<Map<String, dynamic>>()
        .where(
          (meal) => !_isExcludedCategory((meal['strCategory'] ?? '').toString()),
        )
        .map(Meal.fromJson)
        .toList();
  }

  Future<MealDetail> fetchMealDetail(String id) async {
    final uri = Uri.parse('$_baseUrl/lookup.php?i=$id');
    final body = await _getJson(uri);
    final list = body['meals'];
    if (list is! List || list.isEmpty) {
      throw const MealApiException('Recipe not found.');
    }
    final first = list.first;
    if (first is! Map<String, dynamic>) {
      throw const MealApiException('Unexpected detail payload.');
    }
    return MealDetail.fromJson(first);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        throw MealApiException(
          'Request failed (${response.statusCode}). Please try again.',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const MealApiException('Unexpected response format.');
      }
      return decoded;
    } on TimeoutException {
      throw const MealApiException(
        'Network timed out. Check your connection.',
      );
    } on FormatException {
      throw const MealApiException('Could not parse server response.');
    } on MealApiException {
      rethrow;
    } catch (e) {
      throw MealApiException('Network error: $e');
    }
  }

  void dispose() => _client.close();
}
