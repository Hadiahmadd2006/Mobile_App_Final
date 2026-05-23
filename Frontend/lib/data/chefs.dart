/// Short, researched bios for the chefs featured in the Michelin
/// collection. Keys must match the `chef` field on a [MichelinRecipe].
const Map<String, String> kChefBios = {
  'Gordon Ramsay':
      'British chef and restaurateur whose three-Michelin-star Restaurant '
          'Gordon Ramsay in London has held its rating for over two decades — '
          'classic French technique with British produce.',
  'Thomas Keller':
      'The only American chef to hold two simultaneous three-star restaurants '
          '— The French Laundry in Yountville and Per Se in New York — both '
          'icons of refined American cuisine.',
  'Massimo Bottura':
      'Chef-patron of three-starred Osteria Francescana in Modena, celebrated '
          'for daring, witty reinterpretations of Italian tradition and a '
          'Slow Food sensibility.',
  'Joël Robuchon':
      'The most-Michelin-starred chef in history. His pommes purée and '
          '"L\'Atelier" concept reshaped late-20th-century French dining.',
  'Heston Blumenthal':
      'Father of multi-sensory cooking at the three-star Fat Duck. Dinner by '
          'Heston in London revives historical British dishes through a '
          'modern lens.',
  'Clare Smyth':
      'The first female chef to run a restaurant rated three Michelin stars in '
          'the UK — Core by Clare Smyth in London — built around British '
          'ingredients.',
  'Carlo Cracco':
      'Milan’s contemporary auteur, blending Italian tradition with modern '
          'technique at Ristorante Cracco inside the Galleria Vittorio '
          'Emanuele II.',
  'Alain Ducasse':
      'French chef whose global empire spans more than thirty restaurants, '
          'with three Michelin stars at Le Louis XV in Monte-Carlo for nearly '
          'four decades.',
  'René Redzepi':
      'Co-founder and chef of Noma in Copenhagen, leader of the New Nordic '
          'movement and four-times named the world’s best restaurant.',
};

String? chefBio(String chef) => kChefBios[chef];
