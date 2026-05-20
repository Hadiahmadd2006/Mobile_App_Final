class Meal {
  final String id;
  final String name;
  final String thumbnailUrl;

  const Meal({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: (json['idMeal'] ?? '').toString(),
      name: (json['strMeal'] ?? '').toString(),
      thumbnailUrl: (json['strMealThumb'] ?? '').toString(),
    );
  }

  @override
  String toString() => 'Meal($id, $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Meal && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
