// Kategoriler: Basit heuristik (herkes bir kategoriye düşsün diye gevşek)
enum IngredientCategory { vegan, vegetarian, glutenFree, lactoseFree }

class CategoryHelper {
  static String keyOf(dynamic ing) {
    final n = (ing.core?.primaryName ?? '').toString().toLowerCase();
    return n;
  }

  static List<String> _allNames(dynamic ing) {
    final list = <String>[];
    final primary = (ing.core?.primaryName ?? '').toString();
    if (primary.isNotEmpty) list.add(primary.toLowerCase());

    final names = ing.core?.names;
    if (names is Map) {
      names.forEach((_, v) {
        if (v is String) {
          if (v.isNotEmpty) list.add(v.toLowerCase());
        } else if (v is List) {
          for (final s in v) {
            final ss = s.toString();
            if (ss.isNotEmpty) list.add(ss.toLowerCase());
          }
        }
      });
    }
    return list;
  }

  static bool _containsAny(List<String> pool, List<String> needles) {
    for (final p in pool) {
      for (final n in needles) {
        if (p.contains(n)) return true;
      }
    }
    return false;
  }

  static bool isVegan(dynamic ing) {
    final names = _allNames(ing);
    // Eğer hayvansal anahtar kelimeler YOKSA ve isimler var ise vegan say.
    if (_containsAny(names, ['gelatin','jelatin','balık','fish','et','tavuk','karides','sığır','domuz','peynir','yumurta'])) {
      return false;
    }
    if (_containsAny(names, ['vegan'])) return true;
    // Karşıt kelime yoksa vejetaryen + vegan belirsiz → false bırakma: çok sığma, burada true verelim.
    return true;
  }

  static bool isVegetarian(dynamic ing) {
    final names = _allNames(ing);
    if (_containsAny(names, ['jelatin','gelatin','balık yağı','balıkyağı','fish oil'])) return false;
    return true; // default çoğunu kapsa
  }

  static bool isGlutenFree(dynamic ing) {
    final names = _allNames(ing);
    if (_containsAny(names, ['gluten','buğday','bugday','arpa','çavdar','cavdar','麦'])) return false;
    return true;
  }

  static bool isLactoseFree(dynamic ing) {
    final names = _allNames(ing);
    if (_containsAny(names, ['laktoz','laktose','lactose','milk','süt','sut','peynir','yoğurt','yogurt','cream'])) {
      // eğer açıkça laktozsuz yazıyorsa override
      if (_containsAny(names, ['laktozsuz','lactose free'])) return true;
      return false;
    }
    return true;
  }

  static bool match(dynamic ing, IngredientCategory cat) {
    switch (cat) {
      case IngredientCategory.vegan: return isVegan(ing);
      case IngredientCategory.vegetarian: return isVegetarian(ing);
      case IngredientCategory.glutenFree: return isGlutenFree(ing);
      case IngredientCategory.lactoseFree: return isLactoseFree(ing);
    }
  }

  static String label(IngredientCategory c) {
    switch (c) {
      case IngredientCategory.vegan: return 'Vegan';
      case IngredientCategory.vegetarian: return 'Vejetaryen';
      case IngredientCategory.glutenFree: return 'Glutensiz';
      case IngredientCategory.lactoseFree: return 'Laktozsuz';
    }
  }
}