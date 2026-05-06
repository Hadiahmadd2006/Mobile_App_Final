class Ingredient {
  final String name;
  final String measure;

  const Ingredient({required this.name, required this.measure});

  @override
  String toString() => '$measure $name'.trim();
}

class MealDetail {
  final String id;
  final String name;
  final String category;
  final String area;
  final String instructions;
  final String thumbnailUrl;
  final String? youtubeUrl;
  final String? sourceUrl;
  final List<String> tags;
  final List<Ingredient> ingredients;

  const MealDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.instructions,
    required this.thumbnailUrl,
    required this.tags,
    required this.ingredients,
    this.youtubeUrl,
    this.sourceUrl,
  });

  factory MealDetail.fromJson(Map<String, dynamic> json) {
    final ingredients = <Ingredient>[];
    for (var i = 1; i <= 20; i++) {
      final name = (json['strIngredient$i'] ?? '').toString().trim();
      final measure = (json['strMeasure$i'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        ingredients.add(Ingredient(name: name, measure: measure));
      }
    }

    final rawTags = (json['strTags'] ?? '').toString();
    final tags = rawTags.isEmpty
        ? <String>[]
        : rawTags
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();

    String? optionalString(String key) {
      final value = (json[key] ?? '').toString().trim();
      return value.isEmpty ? null : value;
    }

    return MealDetail(
      id: (json['idMeal'] ?? '').toString(),
      name: (json['strMeal'] ?? '').toString(),
      category: (json['strCategory'] ?? '').toString(),
      area: (json['strArea'] ?? '').toString(),
      instructions: (json['strInstructions'] ?? '').toString(),
      thumbnailUrl: (json['strMealThumb'] ?? '').toString(),
      youtubeUrl: optionalString('strYoutube'),
      sourceUrl: optionalString('strSource'),
      tags: tags,
      ingredients: ingredients,
    );
  }

  @override
  String toString() => 'MealDetail($id, $name, $category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MealDetail && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
