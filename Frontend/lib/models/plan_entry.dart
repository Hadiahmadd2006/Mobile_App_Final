/// A single meal scheduled into a specific day + slot of the planner.
class PlanEntry {
  /// 'yyyy-MM-dd' — the day this meal is planned for.
  final String date;

  /// Which meal-of-the-day slot this entry fills.
  final PlanSlot slot;

  final String mealId;
  final String mealName;
  final String mealImage;

  /// `'michelin'` or `'mealdb'` — controls which detail route to open.
  final String source;

  const PlanEntry({
    required this.date,
    required this.slot,
    required this.mealId,
    required this.mealName,
    required this.mealImage,
    required this.source,
  });

  bool get isMichelin => source == 'michelin';

  Map<String, Object?> toMap() => {
    'date': date,
    'slot': slot.name,
    'mealId': mealId,
    'mealName': mealName,
    'mealImage': mealImage,
    'source': source,
  };

  factory PlanEntry.fromMap(Map<String, Object?> map) {
    return PlanEntry(
      date: (map['date'] ?? '').toString(),
      slot: PlanSlot.fromName((map['slot'] ?? 'lunch').toString()),
      mealId: (map['mealId'] ?? '').toString(),
      mealName: (map['mealName'] ?? '').toString(),
      mealImage: (map['mealImage'] ?? '').toString(),
      source: (map['source'] ?? 'mealdb').toString(),
    );
  }
}

enum PlanSlot {
  breakfast,
  lunch,
  dinner;

  String get label {
    switch (this) {
      case PlanSlot.breakfast:
        return 'Breakfast';
      case PlanSlot.lunch:
        return 'Lunch';
      case PlanSlot.dinner:
        return 'Dinner';
    }
  }

  static PlanSlot fromName(String name) {
    return PlanSlot.values.firstWhere(
      (s) => s.name == name,
      orElse: () => PlanSlot.lunch,
    );
  }
}
