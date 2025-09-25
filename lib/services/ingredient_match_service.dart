import '../models/ingredient.dart';
import '../utils/text_format.dart';

/// Skorlanmış eşleşme çıktısı
class IngredientMatch {
  final Ingredient ingredient;
  final double score;
  final int intersectCount;
  final int ingredientTokenCount;
  final Set<String> matchedTokens;
  IngredientMatch({
    required this.ingredient,
    required this.score,
    required this.intersectCount,
    required this.ingredientTokenCount,
    required this.matchedTokens,
  });
}

/// Eşik değerleri tek noktadan ayarlanabilir.
class MatchConfig {
  final double minScore;
  final int minIntersect;
  final int maxResults;
  const MatchConfig({
    this.minScore = 0.12,
    this.minIntersect = 1,
    this.maxResults = 100,
  });
}

class IngredientMatchService {
  final List<_IndexedIngredient> _index = [];
  bool _built = false;

  /// Stop/noise kelimeler
  static const Set<String> _noise = {
    've', 'veya', 'ile', 'vb', 'gibi', 'içerir', 'içeren', 'içinde',
    'içindedir', 'içindekiler', 'ingredients', 'for', 'the', 'of', 'in',
    'üretim', 'partisi', 'seri', 'parti', 'kutu', 'paket', 'ambalaj',
    'saklayınız', 'serin', 'kuru', 'gün', 'son', 'tarih', 'tüketiniz', 'için',
  };

  void build(List<Ingredient> ingredients) {
    _index.clear();
    for (final ing in ingredients) {
      final tokens = <String>{};

      void add(String? raw) {
        if (raw == null) return;
        final norm = normalizeForSearch(raw);
        if (norm.isEmpty) return;
        for (final tk in norm.split(' ')) {
          if (tk.length < 3) continue;
          if (_noise.contains(tk)) continue;
          tokens.add(tk);
        }
      }

      add(ing.core.primaryName);
      final names = ing.core.names;
      for (final v in names.values) {
        if (v is String) add(v);
        if (v is List) {
          for (final e in v) {
            add(e.toString());
          }
        }
      }
      add(ing.core.category);
      add(ing.core.subcategory);
      add(ing.classification.originType);
      for (final w in ing.usage.whereUsed) add(w);
      for (final r in ing.usage.commonRoles) add(r);
      for (final h in ing.health.healthFlags) add(h);
      // risk_factors: string/map destekle
      for (final rf in ing.risk.riskFactors) {
        if (rf is String) add(rf);
        else if (rf is Map) {
          add(rf['title']?.toString());
          add(rf['condition']?.toString());
          add(rf['mechanism']?.toString());
          add(rf['evidence']?.toString());
          add(rf['mitigation']?.toString());
        }
      }

      if (tokens.isNotEmpty) {
        _index.add(_IndexedIngredient(ingredient: ing, tokens: tokens));
      }
    }
    _built = true;
  }

  /// tokens: normalize tek kelimelik token listesi
  /// phrases: çok kelimeli ham ifadeler
  List<IngredientMatch> match({
    required List<String> tokens,
    required List<String> phrases,
    MatchConfig config = const MatchConfig(),
  }) {
    if (!_built) throw StateError('Index henüz build edilmedi.');
    final tokenSet = tokens.toSet();
    final phraseSet = phrases.map(normalizeForSearch).toSet();

    final results = <IngredientMatch>[];

    for (final entry in _index) {
      final intersect = entry.tokens.intersection(tokenSet);
      if (intersect.isEmpty) continue;

      final baseJaccard =
          intersect.length / (entry.tokens.length.clamp(1, 999999));

      // Tam phrase bonus: ingredient primaryName veya synonyms phraseSet içinde aynen geçiyorsa
      double phraseBonus = 0;
      final primaryNorm = normalizeForSearch(entry.ingredient.core.primaryName);
      if (phraseSet.contains(primaryNorm)) {
        phraseBonus += 0.15;
      }

      // Synonyms
      final syn = entry.ingredient.core.names['synonyms'];
      if (syn is List) {
        for (final s in syn) {
          final sn = normalizeForSearch(s.toString());
          if (phraseSet.contains(sn)) {
            phraseBonus += 0.05;
            break;
          }
        }
      }

      // Intersection yoğunluğu
      final denseScore = intersect.length /
          (entry.tokens.length < tokenSet.length
              ? entry.tokens.length
              : tokenSet.length);

      // Nihai skor
      final score =
          (baseJaccard * 0.5) + (denseScore * 0.35) + phraseBonus;

      if (intersect.length >= config.minIntersect && score >= config.minScore) {
        results.add(IngredientMatch(
          ingredient: entry.ingredient,
          score: score,
          intersectCount: intersect.length,
          ingredientTokenCount: entry.tokens.length,
          matchedTokens: intersect,
        ));
      }
    }

    // Sıralama: risk seviyesi (red>yellow>green), skor, intersect sayısı
    results.sort((a, b) {
      int riskRank(String l) {
        switch (l) {
          case 'red':
            return 3;
          case 'yellow':
            return 2;
          case 'green':
            return 1;
          default:
            return 0;
        }
      }

      final r = riskRank(b.ingredient.risk.riskLevel)
          .compareTo(riskRank(a.ingredient.risk.riskLevel));
      if (r != 0) return r;

      final s = b.score.compareTo(a.score);
      if (s != 0) return s;

      return b.intersectCount.compareTo(a.intersectCount);
    });

    if (results.length > config.maxResults) {
      return results.sublist(0, config.maxResults);
    }
    return results;
  }
}

class _IndexedIngredient {
  final Ingredient ingredient;
  final Set<String> tokens;
  _IndexedIngredient({required this.ingredient, required this.tokens});
}