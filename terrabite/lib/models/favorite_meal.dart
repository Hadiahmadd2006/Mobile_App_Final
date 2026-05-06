class FavoriteMeal {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String category;
  final String area;
  final String noteTitle;
  final String noteBody;
  final DateTime savedAt;

  const FavoriteMeal({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.category,
    required this.area,
    required this.noteTitle,
    required this.noteBody,
    required this.savedAt,
  });

  FavoriteMeal copyWith({
    String? noteTitle,
    String? noteBody,
  }) {
    return FavoriteMeal(
      id: id,
      name: name,
      thumbnailUrl: thumbnailUrl,
      category: category,
      area: area,
      noteTitle: noteTitle ?? this.noteTitle,
      noteBody: noteBody ?? this.noteBody,
      savedAt: savedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'thumbnailUrl': thumbnailUrl,
    'category': category,
    'area': area,
    'noteTitle': noteTitle,
    'noteBody': noteBody,
    'savedAt': savedAt.toIso8601String(),
  };

  factory FavoriteMeal.fromMap(Map<String, Object?> map) {
    return FavoriteMeal(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      thumbnailUrl: (map['thumbnailUrl'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      area: (map['area'] ?? '').toString(),
      noteTitle: (map['noteTitle'] ?? '').toString(),
      noteBody: (map['noteBody'] ?? '').toString(),
      savedAt:
          DateTime.tryParse((map['savedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  @override
  String toString() => 'FavoriteMeal($id, $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FavoriteMeal && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
