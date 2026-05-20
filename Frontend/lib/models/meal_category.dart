class MealCategory {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String description;

  const MealCategory({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.description,
  });

  factory MealCategory.fromJson(Map<String, dynamic> json) {
    return MealCategory(
      id: (json['idCategory'] ?? '').toString(),
      name: (json['strCategory'] ?? '').toString(),
      thumbnailUrl: (json['strCategoryThumb'] ?? '').toString(),
      description: (json['strCategoryDescription'] ?? '').toString(),
    );
  }

  @override
  String toString() => 'MealCategory($id, $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MealCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
