import '../models/michelin_recipe.dart';

/// Hand-curated fine-dining recipes for the Pro collection.
///
/// Researched signature dishes from Michelin-starred chefs. Photos are
/// placeholders — swap for licensed imagery before any real release.
const List<MichelinRecipe> kMichelinRecipes = [
  MichelinRecipe(
    id: 'm1',
    name: 'Beef Wellington',
    chef: 'Gordon Ramsay',
    restaurant: 'Restaurant Gordon Ramsay',
    location: 'London, UK',
    stars: 3,
    tagline: 'Centre-cut fillet wrapped in mushroom duxelles, prosciutto '
        'and golden puff pastry.',
    imageUrl:
        'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=900&q=80',
    ingredients: [
      '800g centre-cut beef fillet',
      '400g chestnut mushrooms, very finely chopped',
      '8 slices prosciutto',
      '500g all-butter puff pastry',
      '2 tbsp English mustard',
      '2 egg yolks, beaten',
      'Olive oil, sea salt, black pepper',
    ],
    steps: [
      'Season the fillet, sear in a screaming-hot pan until browned all '
          'over, then brush with mustard and chill.',
      'Fry the mushrooms with no oil until every drop of moisture is gone '
          'and you have a dry duxelles; cool completely.',
      'On cling film, overlap the prosciutto, spread the duxelles, then '
          'roll the beef up inside into a tight cylinder.',
      'Wrap the chilled parcel in rolled puff pastry, seal the seam, and '
          'glaze all over with egg yolk.',
      'Score the pastry lightly and rest in the fridge for 15 minutes.',
      'Bake at 200°C for 35–40 minutes until deep gold; rest 10 minutes '
          'before carving into thick slices.',
    ],
  ),
  MichelinRecipe(
    id: 'm2',
    name: 'Oysters and Pearls',
    chef: 'Thomas Keller',
    restaurant: 'The French Laundry',
    location: 'Yountville, USA',
    stars: 3,
    tagline: 'A sabayon of pearl tapioca with poached oysters and a '
        'generous spoon of caviar.',
    imageUrl:
        'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=900&q=80',
    ingredients: [
      '60g small pearl tapioca',
      '12 fresh oysters, shucked, liquor reserved',
      '4 egg yolks',
      '200ml crème fraîche',
      '30g caviar',
      'Chives, finely sliced',
    ],
    steps: [
      'Soak the tapioca, then simmer gently in milk until the pearls turn '
          'translucent and tender.',
      'Warm the oysters in their own strained liquor just until the edges '
          'curl; do not boil.',
      'Whisk the yolks with a little oyster liquor over a bain-marie into '
          'a light, airy sabayon.',
      'Fold the warm tapioca and crème fraîche through the sabayon and '
          'season delicately.',
      'Spoon the tapioca into bowls, nestle the oysters on top and finish '
          'with caviar and chives.',
    ],
  ),
  MichelinRecipe(
    id: 'm3',
    name: 'Five Ages of Parmigiano Reggiano',
    chef: 'Massimo Bottura',
    restaurant: 'Osteria Francescana',
    location: 'Modena, Italy',
    stars: 3,
    tagline: 'One cheese, five textures and temperatures — a meditation on '
        'Parmigiano Reggiano.',
    imageUrl:
        'https://images.unsplash.com/photo-1562967914-608f82629710?w=900&q=80',
    ingredients: [
      '400g Parmigiano Reggiano (24 months)',
      '300g Parmigiano Reggiano (36 months)',
      '200ml cream',
      '2 sheets gelatine',
      'Parmigiano rind, for the broth',
      'Sea salt',
    ],
    steps: [
      'Make a warm, light Parmigiano sauce by melting young cheese into '
          'cream over a low heat.',
      'Set a portion with bloomed gelatine into a cool, soft custard.',
      'Whip a chilled Parmigiano foam with an immersion blender.',
      'Bake fine gratings into a crisp, lacy cheese tuile.',
      'Simmer the rinds into a clear, savoury broth as the fifth element.',
      'Plate all five textures together so each spoonful changes.',
    ],
  ),
  MichelinRecipe(
    id: 'm4',
    name: 'Pommes Purée',
    chef: 'Joël Robuchon',
    restaurant: "L'Atelier de Joël Robuchon",
    location: 'Paris, France',
    stars: 3,
    tagline: 'The most famous mashed potato in the world — almost half '
        'butter, silk-smooth.',
    imageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900&q=80',
    ingredients: [
      '1kg La Ratte potatoes, unpeeled',
      '250g cold unsalted butter, diced',
      '200ml whole milk',
      'Coarse sea salt',
    ],
    steps: [
      'Boil the potatoes whole in well-salted water until a knife slides '
          'through cleanly.',
      'Peel while still hot and pass them through a fine drum sieve or '
          'ricer twice.',
      'Return to a low heat and dry the purée out, stirring, for a couple '
          'of minutes.',
      'Beat in the cold butter a few cubes at a time until fully '
          'emulsified and glossy.',
      'Loosen with hot milk to a smooth, ribboning consistency; pass once '
          'more and season.',
    ],
  ),
  MichelinRecipe(
    id: 'm5',
    name: 'Meat Fruit',
    chef: 'Heston Blumenthal',
    restaurant: 'Dinner by Heston Blumenthal',
    location: 'London, UK',
    stars: 2,
    tagline: 'A smooth chicken-liver parfait disguised as a perfect '
        'mandarin — a 14th-century trick.',
    imageUrl:
        'https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=900&q=80',
    ingredients: [
      '400g chicken livers, cleaned',
      '200g unsalted butter',
      '3 eggs',
      '100ml Madeira and port reduction',
      'Mandarin purée and pectin, for the glaze',
      'Toasted brioche, to serve',
    ],
    steps: [
      'Blend the livers with eggs, the alcohol reduction and warm melted '
          'butter into a fine parfait.',
      'Pass through a sieve and cook in a low bain-marie until just set; '
          'chill thoroughly.',
      'Shape the cold parfait into smooth spheres and freeze firm.',
      'Set a bright mandarin glaze with pectin and dip each sphere to coat '
          'it like citrus skin.',
      'Add a clove-stem detail and serve very cold with toasted brioche.',
    ],
  ),
  MichelinRecipe(
    id: 'm6',
    name: 'Herb-Roasted Chicken',
    chef: 'Thomas Keller',
    restaurant: 'Bouchon',
    location: 'Yountville, USA',
    stars: 1,
    tagline: 'Keller’s lesson in restraint — a dry-brined bird, '
        'salt, heat and patience.',
    imageUrl:
        'https://images.unsplash.com/photo-1562967914-608f82629710?w=900&q=80',
    ingredients: [
      '1 whole free-range chicken (1.5kg)',
      'Generous coarse salt and black pepper',
      '1 bunch thyme',
      'Dijon mustard, to finish',
    ],
    steps: [
      'Dry the chicken thoroughly inside and out — dry skin is crisp skin.',
      'Truss the bird tightly and season aggressively all over with salt '
          'and pepper.',
      'Roast at 230°C, undisturbed, for about 50–60 minutes until deeply '
          'golden.',
      'Add the thyme for the last few minutes and baste with the rendered '
          'fat.',
      'Rest for 15 minutes, brush with a little mustard, then carve.',
    ],
  ),
  MichelinRecipe(
    id: 'm7',
    name: 'Isle of Mull Scallop',
    chef: 'Clare Smyth',
    restaurant: 'Core by Clare Smyth',
    location: 'London, UK',
    stars: 3,
    tagline: 'A single hand-dived scallop, roasted in its shell with '
        'seaweed butter.',
    imageUrl:
        'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=900&q=80',
    ingredients: [
      '4 large hand-dived scallops, in the shell',
      '120g unsalted butter',
      '2 tbsp dried dulse seaweed',
      '1 lemon',
      'Sea salt',
    ],
    steps: [
      'Blend soft butter with finely ground dried seaweed and a little '
          'salt; chill into a log.',
      'Open the scallops, clean carefully and return each to a cleaned '
          'half shell.',
      'Top with a disc of seaweed butter and roast hot until just opaque '
          'and barely set.',
      'Spoon the foaming shell butter back over the scallop.',
      'Finish with a few drops of lemon and serve in the shell.',
    ],
  ),
  MichelinRecipe(
    id: 'm8',
    name: 'Risotto allo Zafferano',
    chef: 'Carlo Cracco',
    restaurant: 'Ristorante Cracco',
    location: 'Milan, Italy',
    stars: 1,
    tagline: 'The golden Milanese risotto — saffron, bone marrow and a '
        'glossy butter mantecatura.',
    imageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=900&q=80',
    ingredients: [
      '320g Carnaroli rice',
      '1 generous pinch saffron threads',
      '1.2L hot beef stock',
      '40g beef bone marrow',
      '80g cold butter',
      '60g grated Parmigiano',
      '1 small onion, finely diced',
    ],
    steps: [
      'Soften the onion and marrow gently, then toast the rice until the '
          'grains turn glassy.',
      'Add hot stock a ladle at a time, stirring, keeping the rice always '
          'just covered.',
      'Bloom the saffron in a little stock and stir it in halfway through '
          'the cooking.',
      'Cook to al dente — about 16 minutes — keeping the risotto loose '
          'and wavy.',
      'Off the heat, beat in cold butter and Parmigiano vigorously for a '
          'glossy mantecatura.',
      'Rest one minute, then plate so it spreads in a smooth, even layer.',
    ],
  ),
  MichelinRecipe(
    id: 'm9',
    name: 'Rum Baba',
    chef: 'Alain Ducasse',
    restaurant: 'Le Louis XV',
    location: 'Monte-Carlo, Monaco',
    stars: 3,
    tagline: 'A feather-light yeast cake soaked at the table with your '
        'choice of aged rum.',
    imageUrl:
        'https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=900&q=80',
    ingredients: [
      '250g strong flour',
      '10g fresh yeast',
      '4 eggs',
      '90g soft butter',
      '500ml light sugar syrup',
      'Aged rum, to serve',
      'Lightly whipped cream',
    ],
    steps: [
      'Work the flour, yeast and eggs into a soft, elastic dough, then '
          'beat in the butter.',
      'Prove until doubled, knock back and pipe into baba moulds.',
      'Prove again, then bake at 180°C until golden and well risen.',
      'Soak the warm babas in the warm syrup until completely saturated '
          'and glistening.',
      'Serve doused with aged rum at the table and a quenelle of cream.',
    ],
  ),
  MichelinRecipe(
    id: 'm10',
    name: 'Salt-Baked Celeriac',
    chef: 'René Redzepi',
    restaurant: 'Noma',
    location: 'Copenhagen, Denmark',
    stars: 3,
    tagline: 'A whole celeriac baked in a salt crust until it eats like '
        'slow-roasted meat.',
    imageUrl:
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=900&q=80',
    ingredients: [
      '1 large celeriac, scrubbed',
      '1kg coarse salt',
      '3 egg whites',
      'Brown butter, for basting',
      'Toasted hazelnuts and herbs',
    ],
    steps: [
      'Mix the salt with egg white into a damp sand and pack it fully '
          'around the celeriac.',
      'Bake at 180°C for around 2 hours until a skewer slides through the '
          'centre easily.',
      'Crack off the salt crust and peel away the skin to reveal the '
          'tender root.',
      'Carve into thick slices and baste generously with nutty brown '
          'butter in a hot pan.',
      'Finish with toasted hazelnuts, herbs and a little of the basting '
          'butter.',
    ],
  ),
];

MichelinRecipe? michelinRecipeById(String id) {
  for (final recipe in kMichelinRecipes) {
    if (recipe.id == id) return recipe;
  }
  return null;
}
