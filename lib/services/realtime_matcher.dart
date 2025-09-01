import 'dart:math';
import '../utils/normalize.dart';
import 'dictionary_builder.dart';

class MatchCandidate {
  final int ingredientIndex;
  double score;
  int hits;
  final Set<String> matchedUnits;
  MatchCandidate({
    required this.ingredientIndex,
    this.score = 0,
    this.hits = 0,
    Set<String>? matchedUnits,
  }) : matchedUnits = matchedUnits ?? <String>{};
}

class RealTimeMatcher {
  final Dictionary dict;
  final _recentCounts = <String, int>{};
  final int recentWindow;
  RealTimeMatcher(this.dict, {this.recentWindow = 200});

  double _idf(String unit) {
    final df = dict.dfCache[unit];
    if (df == null || df == 0) return 0.0;
    return log((dict.entries.length + 1) / df);
  }

  Map<int, MatchCandidate> matchTokens(List<String> lineTokens,
      {int maxPhraseLen = 5}) {
    final map = <int, MatchCandidate>{};

    for (final t in lineTokens) {
      final docs = dict.tokenIndex[t];
      if (docs == null) continue;
      final idf = _idf(t);
      for (final idx in docs) {
        final c =
            map.putIfAbsent(idx, () => MatchCandidate(ingredientIndex: idx));
        c.hits++;
        final tokenScore = 0.55 + min(0.45, idf * 0.12);
        if (c.matchedUnits.add(t)) {
          c.score += tokenScore;
        }
      }
    }

    final maxLen = min(maxPhraseLen, lineTokens.length);
    for (int len = maxLen; len >= 2; len--) {
      for (int i = 0; i + len <= lineTokens.length; i++) {
        final phrase = lineTokens.sublist(i, i + len).join(' ');
        final docs = dict.phraseIndex[phrase];
        if (docs == null) continue;
        final idf = _idf(phrase);
        for (final idx in docs) {
          final c =
              map.putIfAbsent(idx, () => MatchCandidate(ingredientIndex: idx));
            final phraseScore = (0.6 + 0.15 * (len - 2)) + min(0.5, idf * 0.20);
          if (c.matchedUnits.add(phrase)) {
            c.score += phraseScore;
            c.hits++;
          }
        }
      }
    }

    double rawMean = 0;
    if (map.isNotEmpty) {
      rawMean =
          map.values.map((e) => e.score).reduce((a, b) => a + b) / map.length;
    }
    final adaptiveFloor = max(0.6, rawMean * 0.45);
    map.removeWhere((_, c) => c.score < adaptiveFloor);
    return map;
  }

  List<_FlattenedMatch> finalizeFrame(List<List<String>> allLineTokens) {
    final agg = <int, MatchCandidate>{};
    for (final lineTokens in allLineTokens) {
      final partial = matchTokens(lineTokens);
      partial.forEach((k, v) {
        final a = agg.putIfAbsent(k, () => v);
        if (!identical(a, v)) {
          a.score = max(a.score, v.score) +
              (a.score == v.score ? 0 : min(a.score, v.score) * 0.1);
          a.hits += v.hits;
          a.matchedUnits.addAll(v.matchedUnits);
        }
      });
    }

    agg.forEach((idx, c) {
      final canon = dict.entries[idx].canonical;
      final prev = _recentCounts[canon] ?? 0;
      final boost = log(2 + prev) / log(4);
      c.score *= (1 + 0.25 * boost);
      _recentCounts[canon] = prev + 1;
    });

    if (_recentCounts.length > recentWindow) {
      _recentCounts.removeWhere((_, v) => v < 2);
      _recentCounts.updateAll((_, v) => v > 1 ? v - 1 : v);
    }

    final list = agg.values
        .map((c) {
          final e = dict.entries[c.ingredientIndex];
          return _FlattenedMatch(
            canonical: e.canonical,
            risk: e.riskLevel,
            score: c.score,
            hits: c.hits,
            units: c.matchedUnits.toList(),
          );
        })
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return list;
  }
}

class _FlattenedMatch {
  final String canonical;
  final String risk;
  final double score;
  final int hits;
  final List<String> units;
  _FlattenedMatch({
    required this.canonical,
    required this.risk,
    required this.score,
    required this.hits,
    required this.units,
  });
}