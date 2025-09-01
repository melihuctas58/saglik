import '../models/ingredient.dart';
import '../utils/normalize.dart';
import 'package:flutter/foundation.dart';

class DictionaryEntry {
  final int ingredientIndex;
  final String canonical; // normalized primary name
  final String riskLevel;
  DictionaryEntry({
    required this.ingredientIndex,
    required this.canonical,
    required this.riskLevel,
  });
}

class Dictionary {
  final Map<String, Set<int>> tokenIndex;
  final Map<String, Set<int>> phraseIndex;
  final List<DictionaryEntry> entries;
  final Map<int, Set<String>> ingredientPhrases; // reverse mapping
  final Map<String,int> dfCache;
  Dictionary({
    required this.tokenIndex,
    required this.phraseIndex,
    required this.entries,
    required this.ingredientPhrases,
    required this.dfCache,
  });
}

class DictionaryBuilder {
  static final DictionaryBuilder instance = DictionaryBuilder._();
  DictionaryBuilder._();

  Future<Dictionary> build(List<Ingredient> ingredients,
      {int maxPhraseLen = 5, bool isolate = true}) async {
    if (isolate) {
      return compute<_BuildArgs, Dictionary>(_buildIsolate, _BuildArgs(
        ingredients: ingredients,
        maxPhraseLen: maxPhraseLen,
      ));
    } else {
      return _doBuild(ingredients, maxPhraseLen);
    }
  }

  static Dictionary _buildIsolate(_BuildArgs args) =>
      DictionaryBuilder.instance._doBuild(
          args.ingredients, args.maxPhraseLen);

  Dictionary _doBuild(List<Ingredient> ingredients, int maxPhraseLen) {
    final tokenIndex = <String, Set<int>>{};
    final phraseIndex = <String, Set<int>>{};
    final entries = <DictionaryEntry>[];
    final reverse = <int, Set<String>>{};
    final dfCache = <String,int>{};

    for (var i=0; i<ingredients.length; i++) {
      final ing = ingredients[i];
      final primaryRaw = ing.core.primaryName ?? '';
      if (primaryRaw.trim().isEmpty) continue;
      final primaryNorm = normalizePhrase(primaryRaw);
      final risk = ing.risk.riskLevel ?? 'other';
      entries.add(DictionaryEntry(
        ingredientIndex: i,
        canonical: primaryNorm,
        riskLevel: risk,
      ));

      final phraseSet = <String>{};

      void addPhrase(String raw) {
        final norm = normalizePhrase(raw);
        if (norm.isEmpty) return;
        phraseSet.add(norm);
      }

      // Core names
      addPhrase(primaryRaw);
      ing.core.names.forEach((k,v){
        if (v is String) addPhrase(v);
        else if (v is List) {
          for (final e in v) {
            addPhrase(e.toString());
          }
        }
      });

      // Optional expansions
      for (final w in ing.risk.riskFactors) {
        if (w is String && w.length <= 40) addPhrase(w);
      }

      // Build tokens + ngram
      final allTokens = <String>{};
      for (final ph in phraseSet.toList()) {
        final tokens = tokenize(ph);
        for (final t in tokens) {
          allTokens.add(t);
        }
        final maxLen = tokens.length < maxPhraseLen ? tokens.length : maxPhraseLen;
        for (int len=2; len<=maxLen; len++) {
          for (int j=0; j+len<=tokens.length; j++) {
            phraseSet.add(joinTokens(tokens, j, len));
          }
        }
      }

      // E-code extraction
      final eCodes = RegExp(r'\be\d{3}[a-z]?\b');
      for (final ph in phraseSet.toList()) {
        for (final m in eCodes.allMatches(ph)) {
          phraseSet.add(m.group(0)!);
        }
      }

      // Indexing
      for (final t in allTokens) {
        tokenIndex.putIfAbsent(t, ()=> <int>{}).add(i);
        dfCache[t] = (dfCache[t] ?? 0) + 1;
      }
      for (final ph in phraseSet) {
        if (ph.contains(' ')) {
          phraseIndex.putIfAbsent(ph, ()=> <int>{}).add(i);
          dfCache[ph] = (dfCache[ph] ?? 0) + 1;
        } else {
          // Tek kelimelik phrase zaten tokenIndex’te
        }
      }
      reverse[i] = phraseSet;
    }

    return Dictionary(
      tokenIndex: tokenIndex,
      phraseIndex: phraseIndex,
      entries: entries,
      ingredientPhrases: reverse,
      dfCache: dfCache,
    );
  }
}

class _BuildArgs {
  final List<Ingredient> ingredients;
  final int maxPhraseLen;
  _BuildArgs({required this.ingredients, required this.maxPhraseLen});
}