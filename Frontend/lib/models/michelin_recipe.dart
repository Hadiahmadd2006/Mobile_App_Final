/// A curated fine-dining recipe for the Pro "Michelin" collection.
///
/// This is hand-authored static content (not from TheMealDB) — researched
/// signature dishes from starred chefs.
class MichelinRecipe {
  final String id;
  final String name;
  final String chef;
  final String restaurant;
  final String location;

  /// Michelin star count of the chef's flagship restaurant (1–3).
  final int stars;
  final String tagline;
  final String imageUrl;
  final List<String> ingredients;

  /// Clean, ordered preparation steps (also drives Cooking Mode later).
  final List<String> steps;

  const MichelinRecipe({
    required this.id,
    required this.name,
    required this.chef,
    required this.restaurant,
    required this.location,
    required this.stars,
    required this.tagline,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
  });
}
