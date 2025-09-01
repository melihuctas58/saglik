import '../models/ingredient.dart';
import '../utils/text_format.dart';

class IngredientIndexEntry {
  final Ingredient ingredient;
  final Set<String> tokens;
  IngredientIndexEntry({required this.ingredient, required this.tokens});
}

class IngredientIndexService {
  final List<IngredientIndexEntry> _entries = [];

  void buildIndex(List<Ingredient> ingredients) {
    _entries.clear();
    for (final ing in ingredients) {
      final t = <String>{};
      void addRaw(String? s) {
        if (s == null) return;
        final norm = normalizeForSearch(s);
        if (norm.isEmpty) return;
        t.addAll(norm.split(' '));
      }

      addRaw(ing.core.primaryName);
      final names = ing.core.names;
      for (final v in names.values) {
        if (v is String) addRaw(v);
        if (v is List) {
          for (final e in v) {
            addRaw(e.toString());
          }
        }
      }
      addRaw(ing.core.category);
      addRaw(ing.core.subcategory);
      addRaw(ing.classification.originType);
      ing.usage.whereUsed.forEach(addRaw);
      ing.usage.commonRoles.forEach(addRaw);
      ing.health.healthFlags.forEach(addRaw);
      // risk factors da eklenebilir
      _entries.add(IngredientIndexEntry(ingredient: ing, tokens: t));
    }
  }

  /// Basit kısmi eşleşme: tanınan token listesi -> skor eşleşmesi
  List<Ingredient> matchTokens(List<String> tokens) {
    final result = <_MatchScore>[];
    final tokenSet = tokens.toSet();
    for (final e in _entries) {
      final inter = e.tokens.intersection(tokenSet);
      if (inter.isNotEmpty) {
        final score = inter.length / (e.tokens.length + 0.0001);
        result.add(_MatchScore(e.ingredient, score));
      }
    }
    result.sort((a, b) => b.score.compareTo(a.score));
    // Basit threshold (skor veya intersection)
    return result.where((m) => m.score > 0.02).map((m) => m.ingredient).toList();
  }
}

class _MatchScore {
  final Ingredient ingredient;
  final double score;
  _MatchScore(this.ingredient, this.score);
}