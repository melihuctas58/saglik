import 'dart:math';
import '../models/ingredient.dart';
import '../utils/simple_normalize.dart';

class SimpleIngredientMatch {
  final Ingredient ingredient;
  final double score;
  final int intersection;
  final bool exact;
  final String matchedSegment; // 'live' olabilir
  final List<String> matchedTokens;
  SimpleIngredientMatch({
    required this.ingredient,
    required this.score,
    required this.intersection,
    required this.exact,
    required this.matchedSegment,
    required this.matchedTokens,
  });

  SimpleIngredientMatch copyWith({
    double? score,
    int? intersection,
    bool? exact,
    String? matchedSegment,
    List<String>? matchedTokens,
  }) {
    return SimpleIngredientMatch(
      ingredient: ingredient,
      score: score ?? this.score,
      intersection: intersection ?? this.intersection,
      exact: exact ?? this.exact,
      matchedSegment: matchedSegment ?? this.matchedSegment,
      matchedTokens: matchedTokens ?? this.matchedTokens,
    );
  }
}

class SimpleIngredientMatcher {
  final List<Ingredient> _ingredients;
  final Map<String, Ingredient> _phraseMap = {};
  final List<_Indexed> _indexed = [];
  final Map<String, Set<int>> _tokenToEntries = {};
  bool _built = false;

  SimpleIngredientMatcher(this._ingredients) {
    _build();
  }

  void _build() {
    for (int ingIdx=0; ingIdx<_ingredients.length; ingIdx++) {
      final ing = _ingredients[ingIdx];
      final primRaw = (ing.core.primaryName ?? '').trim();
      if (primRaw.isEmpty) continue;

      final phraseSet = <String>{};
      phraseSet.add(primRaw);

      ing.core.names.forEach((k,v){
        if (v is String) phraseSet.add(v);
        else if (v is List) {
          for (final s in v) {
            phraseSet.add(s.toString());
          }
        }
      });

      final tokenSet = <String>{};

      for (final ph in phraseSet) {
        final norm = SimpleNormalize.basic(ph);
        if (norm.isEmpty) continue;
        final lower = norm.toLowerCase();
        _phraseMap[lower] = ing;
        final ascii = SimpleNormalize.lowerAscii(lower);
        _phraseMap[ascii] = ing;

        for (final t in SimpleNormalize.tokenize(lower)) {
          final tl = t.toLowerCase();
          tokenSet.add(tl);
          tokenSet.add(SimpleNormalize.lowerAscii(tl));
        }
      }

      if (tokenSet.isNotEmpty) {
        final idxObj = _Indexed(ingredient: ing, tokens: tokenSet);
        _indexed.add(idxObj);
        for (final tk in tokenSet) {
          _tokenToEntries.putIfAbsent(tk, () => <int>{}).add(_indexed.length - 1);
        }
      }
    }
    _built = true;
  }

  // Eski full text pipeline (virgüllere göre segment)
  List<SimpleIngredientMatch> matchFromFullText(String fullText,
      {double minScore = 0.35}) {
    final segment = _extractIngredientsSegment(fullText);
    final segments = _splitSegments(segment);
    final acc = <SimpleIngredientMatch>[];

    for (final seg in segments) {
      final m = matchSingleSegment(seg, minScore: minScore);
      if (m != null) acc.add(m);
    }

    // Ingredient bazında best
    final bestMap = <Ingredient, SimpleIngredientMatch>{};
    for (final r in acc) {
      final prev = bestMap[r.ingredient];
      if (prev == null || r.score > prev.score) {
        bestMap[r.ingredient] = r;
      }
    }

    final list = bestMap.values.toList()
      ..sort((a,b){
        final s = b.score.compareTo(a.score);
        if (s != 0) return s;
        return b.intersection.compareTo(a.intersection);
      });

    return list;
  }

  // Canlı mod için word element token seti üzerinden direkt scoring
  List<SimpleIngredientMatch> matchFromTokens(Set<String> tokens,
      {double minScore = 0.30}) {
    if (!_built || tokens.isEmpty) return const [];

    final lowerTokens = tokens.map((e)=> e.toLowerCase()).toSet();
    final asciiTokens = lowerTokens.map(SimpleNormalize.lowerAscii).toSet();
    final unionTokens = {...lowerTokens, ...asciiTokens};

    final candidateScores = <int, _TempScore>{};

    for (final t in unionTokens) {
      final idxSet = _tokenToEntries[t];
      if (idxSet == null) continue;
      for (final entryIndex in idxSet) {
        final entry = _indexed[entryIndex];
        final cs = candidateScores.putIfAbsent(entryIndex, () => _TempScore());
        cs.tokensHit.add(t);
      }
    }

    final results = <SimpleIngredientMatch>[];
    candidateScores.forEach((entryIndex, temp) {
      final entry = _indexed[entryIndex];
      final inter = temp.tokensHit.intersection(entry.tokens);
      if (inter.isEmpty) return;

      final ratio = inter.length / max(1, entry.tokens.length);
      double score = ratio;
      if (inter.length >= 3) score += 0.12;
      if (score < minScore) return;

      results.add(SimpleIngredientMatch(
        ingredient: entry.ingredient,
        score: score.clamp(0,1),
        intersection: inter.length,
        exact: false,
        matchedSegment: 'live',
        matchedTokens: inter.toList(),
      ));
    });

    // Aynı ingredient (birden fazla index yok zaten) – yinele yok.
    results.sort((a,b){
      final s = b.score.compareTo(a.score);
      if (s != 0) return s;
      return b.intersection.compareTo(a.intersection);
    });

    return results;
  }

  // Segment bazlı tek sonuç
  SimpleIngredientMatch? matchSingleSegment(String rawSegment,
      {double minScore = 0.35}) {
    if (!_built) return null;
    var segNorm = SimpleNormalize.basic(rawSegment);
    if (segNorm.isEmpty) return null;
    final segLower = segNorm.toLowerCase();
    final segAscii = SimpleNormalize.lowerAscii(segLower);

    Ingredient? exactIng = _phraseMap[segLower] ?? _phraseMap[segAscii];

    final segTokensLower = SimpleNormalize.tokenize(segLower).map((e)=> e.toLowerCase()).toList();
    final segTokensAscii = segTokensLower.map(SimpleNormalize.lowerAscii).toList();
    final segTokenSet = {...segTokensLower, ...segTokensAscii};

    SimpleIngredientMatch? best;

    for (final idx in _indexed) {
      bool exact = false;
      if (exactIng != null && idx.ingredient == exactIng) {
        exact = true;
      } else {
        final prim = (idx.ingredient.core.primaryName ?? '').toLowerCase();
        if (prim.isNotEmpty) {
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

      final inter = idx.tokens.intersection(segTokenSet);
      if (inter.isEmpty && !exact) continue;

      final base = exact ? 1.0 : inter.length / max(1, idx.tokens.length);
      final boost = exact ? 0.30 : (inter.length >= 3 ? 0.15 : 0.0);
      final score = (base + boost).clamp(0, 1).toDouble();

      if (score >= minScore) {
        final match = SimpleIngredientMatch(
          ingredient: idx.ingredient,
            score: score,
          intersection: inter.length,
          exact: exact,
          matchedSegment: segNorm,
          matchedTokens: inter.toList(),
        );
        if (best == null || match.score > best.score) best = match;
      }
    }
    return best;
  }

  // İçindekiler marker arama
  String _extractIngredientsSegment(String full) {
    final lower = full.toLowerCase();
    final idx = lower.indexOf('içindekiler');
    final idx2 = lower.indexOf('icindekiler');
    int start = -1;
    if (idx != -1) start = idx + 'içindekiler'.length;
    else if (idx2 != -1) start = idx2 + 'icindekiler'.length;
    if (start == -1) return full;
    final slice = full.substring(start);
    return slice.length > 3000 ? slice.substring(0, 3000) : slice;
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

class _TempScore {
  final Set<String> tokensHit = {};
}