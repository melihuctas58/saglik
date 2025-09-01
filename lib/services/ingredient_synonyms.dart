class IngredientSynonyms {
  // canonical -> synonyms
  static final Map<String, Set<String>> synonyms = {
    'askorbik asit': {'e300','ascorbic acid','vitamin c','askorbik'},
    'lesitin': {'lecithin','e322','soya lesitini','soya lesitin','soy lecithin'},
    'sitrik asit': {'e330','citric acid','sitrik'},
    'monosodyum glutamat': {'e621','msg','monosodyum glutamatı','glutamat'},
    'palmiye yağı': {'palm oil','palmyag','palmyagi','palm'},
    'ayçiçek yağı': {'aycicek yagi','sunflower oil'},
    'mısır nişastası': {'misir nisastasi','corn starch','cornstarch'},
    // Buraya daha çok ekleyebilirsin...
  };

  static final Map<String,String> eCodeToCanonical = {
    'e300':'askorbik asit',
    'e322':'lesitin',
    'e330':'sitrik asit',
    'e621':'monosodyum glutamat',
  };

  static bool isECode(String s) => RegExp(r'^e\d{3}[a-z]?$').hasMatch(s);
}