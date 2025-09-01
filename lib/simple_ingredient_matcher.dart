import '../models/ingredient.dart';
import '../utils/simple_normalize.dart';
import 'dart:math';

class SimpleIngredientMatch {
  final Ingredient ingredient;
  final double score;
  final int intersection;
  final bool exact;
  final String matchedSegment;
  final List<String> matchedTokens;
  SimpleIngredientMatch({
    required this.ingredient,
    required this.score,
    required this.intersection,
    required this.exact,
    required this.matchedSegment,
    required this.matchedTokens,
  });
}

class SimpleIngredientMatcher {
  final List<Ingredient> _ingredients;
  final Map<String, Ingredient> _phraseMap = {};
  final List<_Indexed> _indexed = [];

  SimpleIngredientMatcher(this._ingredients) {
    _build();
  }

  void _build() {
    for (final ing in _ingredients) {
      final primRaw = (ing.core.primaryName ?? '').trim();
      if (primRaw.isEmpty) continue;

      // primary + synonyms (names field)
      final phraseSet = <String>{};
      phraseSet.add(primRaw);
      ing.core.names.forEach((k,v){
        if (v is String) {
          phraseSet.add(v);
        } else if (v is List) {
          for (final s in v) {
            phraseSet.add(s.toString());
          }
        }
      });

      // Index phrases & tokens
      final tokenSet = <String>{};
      for (final ph in phraseSet) {
        final norm = SimpleNormalize.basic(ph);
        if (norm.isEmpty) continue;
        final lower = norm.toLowerCase();
        _phraseMap[lower] = ing;

        final ascii = SimpleNormalize.lowerAscii(lower);
        _phraseMap[ascii] = ing; // diakritiksiz de ekle

        // Tokens
        for (final t in SimpleNormalize.tokenize(lower)) {
          tokenSet.add(t.toLowerCase());
          tokenSet.add(SimpleNormalize.lowerAscii(t.toLowerCase()));
        }
      }

      if (tokenSet.isNotEmpty) {
        _indexed.add(_Indexed(ingredient: ing, tokens: tokenSet));
      }
    }
  }

  // Ana API – fullText ver, isteğe göre içindekiler segment marker’ı ara, virgül/; split et.
  List<SimpleIngredientMatch> matchFromFullText(String fullText) {
    final segment = _extractIngredientsSegment(fullText);
    final segments = _splitSegments(segment);
    final results = <SimpleIngredientMatch>[];

    for (final seg in segments) {
      final segNormBasic = SimpleNormalize.basic(seg);
      final segLower = segNormBasic.toLowerCase();
      final segAscii = SimpleNormalize.lowerAscii(segLower);

      // 1. Exact phrase match (her iki form)
      Ingredient? exactIng = _phraseMap[segLower] ?? _phraseMap[segAscii];

      // 2. Token bazlı
      final segTokensLower = SimpleNormalize.tokenize(segLower).map((e)=> e.toLowerCase()).toList();
      final segTokensAscii = segTokensLower.map(SimpleNormalize.lowerAscii).toList();
      final segTokenSet = {...segTokensLower, ...segTokensAscii};

      for (final idx in _indexed) {
        bool exact = false;
        if (exactIng != null && idx.ingredient == exactIng) {
          exact = true;
        } else {
          // phrase exact değilse substring fallback
          final prim = (idx.ingredient.core.primaryName ?? '').toLowerCase();
          if (!exact && prim.isNotEmpty) {
            if (segLower.contains(prim)) {
              exact = true;
            } else {
              final primAscii = SimpleNormalize.lowerAscii(prim);
              if (segAscii.contains(primAscii)) {
                exact = true;
              }
            }
          }
        }

        // token intersection
        final inter = idx.tokens.intersection(segTokenSet);
        if (inter.isEmpty && !exact) continue;

        final base = exact ? 1.0 : inter.length / max(1, idx.tokens.length);
        final boost = exact ? 0.3 : (inter.length >= 3 ? 0.15 : 0.0);
        final score = (base + boost).clamp(0, 1).toDouble();

        // Filtre: en az 1 token ya da exact
        if (exact || inter.isNotEmpty) {
          results.add(SimpleIngredientMatch(
            ingredient: idx.ingredient,
            score: score,
            intersection: inter.length,
            exact: exact,
            matchedSegment: segNormBasic,
            matchedTokens: inter.toList(),
          ));
        }
      }
    }

    // Aynı ingredient birden fazla segmentten geldiyse en yüksek scorunu al
    final bestMap = <Ingredient, SimpleIngredientMatch>{};
    for (final r in results) {
      final b = bestMap[r.ingredient];
      if (b == null || r.score > b.score) {
        bestMap[r.ingredient] = r;
      }
    }

    final flat = bestMap.values.toList()
      ..sort((a,b){
        final s = b.score.compareTo(a.score);
        if (s != 0) return s;
        return b.intersection.compareTo(a.intersection);
      });

    return flat.take(60).toList();
  }

  String _extractIngredientsSegment(String full) {
    final lower = full.toLowerCase();
    final idx = lower.indexOf('içindekiler');
    final idx2 = lower.indexOf('icindekiler');
    int start = -1;
    if (idx != -1) start = idx + 'içindekiler'.length;
    else if (idx2 != -1) start = idx2 + 'icindekiler'.length;
    if (start == -1) {
      // fallback: bütün metin
      return full;
    }
    // Sonraki 1200 karakter yeter çoğu pakete
    final slice = full.substring(start);
    return slice.length > 1200 ? slice.substring(0, 1200) : slice;
  }

  List<String> _splitSegments(String seg) {
    final raw = seg
        .replaceAll('\r', ' ')
        .replaceAll('\n', ',')
        .replaceAll('•', ',')
        .replaceAll('·', ',');
    final parts = raw.split(RegExp(r'[;,]'));
    return parts
        .map((p)=> p.trim())
        .where((p)=> p.isNotEmpty && p.length > 1)
        .toList();
  }
}

class _Indexed {
  final Ingredient ingredient;
  final Set<String> tokens;
  _Indexed({required this.ingredient, required this.tokens});
}