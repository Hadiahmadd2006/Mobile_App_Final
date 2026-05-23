/// Pro-gating for regular (TheMealDB) recipes.
///
/// Deterministic by ID — the same meal is always Pro across launches and
/// across devices, without needing a hand-maintained list. Roughly 20%
/// of the catalogue is locked, distributed across every category so
/// every section (Beef, Chicken, Dessert, …) has a few Pro picks.
bool isMealPro(String id) {
  final n = int.tryParse(id);
  if (n == null) return false;
  return n % 5 == 0;
}
