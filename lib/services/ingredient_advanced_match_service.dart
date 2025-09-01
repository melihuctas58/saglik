import 'dart:math';
import '../models/ingredient.dart';
import '../utils/text_format.dart';
import 'token_utils.dart';

class AdvancedMatchConfig {
  final double minScore;
  final int minIntersect;
  final bool allowSingleStrong;
  final double strongIdfMin;
  final int fuzzyMaxDistance;
  final double fuzzyMaxRelative;
  final int maxCandidatesPerToken;
  final int maxResults;

  const AdvancedMatchConfig({
    this.minScore = 0.28,
    this.minIntersect = 2,
    this.allowSingleStrong = true,
    this.strongIdfMin = 4.0,
    this.fuzzyMaxDistance = 2,
    this.fuzzyMaxRelative = 0.25,
    this.maxCandidatesPerToken = 60,
    this.maxResults = 40,
  });
}

class AdvancedIngredientMatch {
  final Ingredient ingredient;
  final double score;
  final int intersectCount;
  final double weightedOverlap;
  final int fuzzyCount;
  final int phraseHits;
  final Set<String> matchedTokens;
  AdvancedIngredientMatch({
    required this.ingredient,
    required this.score,
    required this.intersectCount,
    required this.weightedOverlap,
    required this.fuzzyCount,
    required this.phraseHits,
    required this.matchedTokens,
  });
}

class AdvancedIngredientMatchService {
  final Set<String> _noise = {
    've','veya','ile','vb','gibi','içerir','içeren','içinde','içindedir','içindekiler',
    'ingredients','for','the','of','in','üretim','partisi','seri','parti','kutu','paket',
    'ambalaj','saklayınız','serin','kuru','gün','son','tarih','tüketiniz','için','besin',
    'değerleri','enerji','doğal','saf','katkısız','asit','yağ','tuz','su','aroma'
  };

  final List<_IndexedIngredient> _indexed = [];
  final Map<String, List<int>> _inverted = {}; // token -> doc indices
  final Map<String, int> _df = {}; // document frequency
  bool _built = false;

  void build(List<Ingredient> ingredients) {
    _indexed.clear();
    _inverted.clear();
    _df.clear();

    for (var i = 0; i < ingredients.length; i++) {
      final ing = ingredients[i];
      final tokens = _collectTokens(ing);
      if (tokens.isEmpty) continue;
      _indexed.add(_IndexedIngredient(ingredient: ing, tokens: tokens));
    }

    for (var i = 0; i < _indexed.length; i++) {
      for (final t in _indexed[i].tokens) {
        _inverted.putIfAbsent(t, () => []).add(i);
      }
    }
    for (final e in _inverted.entries) {
      _df[e.key] = e.value.length;
    }
    _built = true;
  }

  Set<String> _collectTokens(Ingredient ing) {
    final set = <String>{};
    void addRaw(String? raw) {
      if (raw == null) return;
      final norm = normalizeForSearch(raw);
      if (norm.isEmpty) return;
      for (final tk in norm.split(' ')) {
        if (tk.length < 3) continue;
        if (_noise.contains(tk)) continue;
        set.add(tk);
      }
    }

    addRaw(ing.core.primaryName);
    final names = ing.core.names;
    for (final v in names.values) {
      if (v is String) addRaw(v);
      if (v is List) {
        for (final s in v) {
          addRaw(s.toString());
        }
      }
    }
    addRaw(ing.core.category);
    addRaw(ing.core.subcategory);
    addRaw(ing.classification.originType);
    for (final w in ing.usage.whereUsed) addRaw(w);
    for (final r in ing.usage.commonRoles) addRaw(r);
    for (final h in ing.health.healthFlags) addRaw(h);
    for (final rf in ing.risk.riskFactors) addRaw(rf);
    return set;
  }

  double _idf(String token) {
    final df = _df[token];
    if (df == null || df == 0) return 0.0;
    final total = _indexed.length;
    return log(1 + total / df);
  }

  List<AdvancedIngredientMatch> match({
    required List<String> queryTokens,
    required List<String> phrases,
    AdvancedMatchConfig config = const AdvancedMatchConfig(),
  }) {
    if (!_built) throw StateError('Index not built');

    // 1. Query temizle
    final qSet = <String>{};
    for (final q in queryTokens) {
      final n = normalizeForSearch(q);
      if (n.isEmpty) continue;
      if (n.length < 3) continue;
      if (_noise.contains(n)) continue;
      qSet.add(n);
    }
    if (qSet.isEmpty) return [];

    // 2. Kandidat toplama
    final candidateScores = <int,int>{};
    for (final qt in qSet) {
      final posting = _inverted[qt];
      if (posting == null) continue;
      final limited = posting.length > config.maxCandidatesPerToken
          ? posting.take(config.maxCandidatesPerToken)
          : posting;
      for (final docId in limited) {
        candidateScores.update(docId, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    if (candidateScores.isEmpty) return [];

    final phraseNorm = phrases.map(normalizeForSearch).toSet();
    final results = <AdvancedIngredientMatch>[];

    candidateScores.forEach((docId, _) {
      final entry = _indexed[docId];
      final intersectTokens = entry.tokens.intersection(qSet);
      final intersectCount = intersectTokens.length;
      if (intersectCount == 0) return;

      // Weighted overlap
      double weighted = 0.0;
      for (final t in intersectTokens) {
        weighted += _idf(t);
      }
      final totalWeighted = entry.tokens
          .where((t) => !_noise.contains(t))
          .map(_idf)
          .fold<double>(0.0, (a, b) => a + b);

      final overlapNorm = totalWeighted == 0.0 ? 0.0 : (weighted / totalWeighted);

      // Phrase bonus
      int phraseHits = 0;
      final primaryNorm = normalizeForSearch(entry.ingredient.core.primaryName);
      if (phraseNorm.contains(primaryNorm)) phraseHits++;
      final syn = entry.ingredient.core.names['synonyms'];
      if (syn is List) {
        for (final s in syn) {
          final sn = normalizeForSearch(s.toString());
          if (phraseNorm.contains(sn)) {
            phraseHits++;
            break;
          }
        }
      }
      final phraseBonus = min(0.30, phraseHits * 0.10);

      // Fuzzy
      final unmatchedQuery = qSet.difference(intersectTokens);
      int fuzzyMatches = 0;
      if (unmatchedQuery.isNotEmpty) {
        outerLoop:
        for (final uq in unmatchedQuery) {
          if (uq.length < 4) continue;
          for (final it in entry.tokens) {
            final len = it.length;
            final maxDistAllowed = min(config.fuzzyMaxDistance,
                (len * config.fuzzyMaxRelative).ceil());
            final d = levenshtein(uq, it, max: maxDistAllowed);
            if (d > 0 && d <= maxDistAllowed) {
              fuzzyMatches++;
              if (fuzzyMatches >= 4) break outerLoop;
              break;
            }
          }
        }
      }
      final fuzzyBonus = min(0.16, fuzzyMatches * 0.04);

      final denseRatio = intersectCount /
          (qSet.length < entry.tokens.length ? qSet.length : entry.tokens.length);

      final score = 0.45 * overlapNorm +
          0.20 * denseRatio +
          0.20 * phraseBonus +
          0.15 * fuzzyBonus;

      final passMulti = (intersectCount >= config.minIntersect && score >= config.minScore);
      bool passSingleStrong = false;
      if (config.allowSingleStrong && intersectCount == 1) {
        final onlyToken = intersectTokens.first;
        final idf = _idf(onlyToken);
        if (idf >= config.strongIdfMin &&
            (phraseHits > 0 || score >= (config.minScore + 0.05))) {
          passSingleStrong = true;
        }
      }
      if (!(passMulti || passSingleStrong)) return;

      results.add(AdvancedIngredientMatch(
        ingredient: entry.ingredient,
        score: score,
        intersectCount: intersectCount,
        weightedOverlap: overlapNorm,
        fuzzyCount: fuzzyMatches,
        phraseHits: phraseHits,
        matchedTokens: intersectTokens,
      ));
    });

    int riskRank(String l) {
      switch (l) {
        case 'red': return 3;
        case 'yellow': return 2;
        case 'green': return 1;
        default: return 0;
      }
    }

    results.sort((a, b) {
      final rr = riskRank(b.ingredient.risk.riskLevel)
          .compareTo(riskRank(a.ingredient.risk.riskLevel));
      if (rr != 0) return rr;
      final sc = b.score.compareTo(a.score);
      if (sc != 0) return sc;
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