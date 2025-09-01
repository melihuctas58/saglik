import 'dart:math';
import '../utils/turkish_norm.dart';
import 'ingredient_synonyms.dart';
import 'ingredient_extraction_config.dart';
import 'token_utils.dart';

class ExtractedIngredient {
  final String canonical;
  final double score;
  final List<String> lines; // hangi satırlardan
  final Set<String> matchedVariants;
  ExtractedIngredient({
    required this.canonical,
    required this.score,
    required this.lines,
    required this.matchedVariants,
  });
}

class ExtractionDebugLine {
  final String raw;
  final Map<String,double> partialScores;
  ExtractionDebugLine({required this.raw, required this.partialScores});
}

class ExtractionResult {
  final List<ExtractedIngredient> ingredients;
  final List<String> rawItems;
  final List<ExtractionDebugLine> debugLines;
  ExtractionResult({
    required this.ingredients,
    required this.rawItems,
    required this.debugLines,
  });
}

class IngredientExtractionService {
  static final IngredientExtractionService _instance = IngredientExtractionService._();
  IngredientExtractionService._();
  factory IngredientExtractionService() => _instance;

  // Noise tokens:
  static const _noise = {
    've','ile','veya','icindekiler','ingredients','icindeki','içindekiler',
    'icinde','içinde','katki','katkı','dogal','doğal','renklendirici','tamamen'
  };

  ExtractionResult extract(String fullText, {ExtractionConfig? override}) {
    final cfg = override ?? ExtractionTuning.config;

    // 1. Segment bul
    final segment = _locateSegment(fullText);
    // 2. Parçala (virgül vb)
    final rawItems = _splitItems(segment);
    // 3. Her item için canonical match scoring
    final lineDebug = <ExtractionDebugLine>[];
    final Map<String,_Accum> accum = {};

    for (final item in rawItems) {
      final normItem = basicNormalize(item);
      if (normItem.isEmpty) continue;

      final variants = _candidateTokens(normItem);
      final partial = <String,double>{};

      for (final v in variants) {
        if (v.isEmpty || _noise.contains(v)) continue;
        final canonical = _mapCanonical(v);
        if (canonical == null) continue;

        final baseScore = _baseVariantScore(v, canonical);
        partial[canonical] = max(partial[canonical] ?? 0, baseScore);
      }

      // Fuzzy sadece canonical bulunmayan kelimelere
      if (cfg.enableFuzzy) {
        final unmatched = variants.where((v)=> !_noise.contains(v)).toList();
        for (final uv in unmatched) {
          final c = _fuzzyCanonical(uv, cfg);
          if (c == null) continue;
          final baseScore = 0.55;
          partial[c] = max(partial[c] ?? 0, baseScore);
        }
      }

      // substring opsiyonu
      if (cfg.enableSubstring) {
        for (final uv in variants) {
          if (uv.length < 5) continue;
          IngredientSynonyms.synonyms.forEach((canon, syns){
            if (partial.containsKey(canon)) return;
            if (uv.contains(canon.split(' ').first) && uv != canon) {
              partial[canon] = 0.5;
            }
          });
        }
      }

      // Partial min line score threshold
      final filtered = partial.entries.where((e) => e.value >= cfg.minLineScore);
      if (filtered.isEmpty) {
        lineDebug.add(ExtractionDebugLine(raw: item, partialScores: partial));
        continue;
      }

      for (final e in filtered) {
        final a = accum.putIfAbsent(e.key, ()=> _Accum());
        a.score = _combineScores(a.score, e.value);
        a.lines.add(item);
        a.variants.add(e.key);
      }
      lineDebug.add(ExtractionDebugLine(raw: item, partialScores: partial));
    }

    // Global occurrences filter
    final out = <ExtractedIngredient>[];
    accum.forEach((canon, acc){
      if (acc.lines.length < ExtractionTuning.config.minGlobalOccurrences) return;
      if (acc.score < ExtractionTuning.config.minIngredientScore) return;
      out.add(ExtractedIngredient(
        canonical: canon,
        score: double.parse(acc.score.toStringAsFixed(3)),
        lines: acc.lines,
        matchedVariants: acc.variants,
      ));
    });

    out.sort((a,b)=> b.score.compareTo(a.score));
    return ExtractionResult(
      ingredients: out,
      rawItems: rawItems,
      debugLines: lineDebug,
    );
  }

  // ----------------- Helpers -----------------
  String _locateSegment(String full) {
    final text = full.replaceAll('\r','\n');
    final lines = text.split('\n');
    int start = -1;
    for (var i=0;i<lines.length;i++){
      final l = lines[i].toLowerCase();
      if (RegExp(r'(içindekiler|icindekiler|ingredients)').hasMatch(l)) {
        start = i;
        break;
      }
    }
    if (start == -1) {
      // fallback: en çok virgül içeren ardışık blok
      return _fallbackLongestCommaBlock(lines);
    }
    final buf = <String>[];
    for (var i=start+1;i<lines.length;i++){
      final raw = lines[i].trim();
      if (raw.isEmpty) break;
      final up = raw.toUpperCase();
      // Yeni bir başlık gibi tamamen büyük harf ve kısa (örn BESİN DEĞERLERİ)
      if (RegExp(r'^[A-ZÇĞİÖŞÜ\s]{4,}$').hasMatch(up) &&
          RegExp(r'[AEIİOÖUÜ]').hasMatch(up)) {
        break;
      }
      buf.add(raw);
    }
    return buf.join(' ');
  }

  String _fallbackLongestCommaBlock(List<String> lines) {
    int bestLen = 0;
    final buf = StringBuffer();
    for (final l in lines) {
      final c = l.split(',').length;
      if (c > bestLen) {
        bestLen = c;
        buf.clear();
        buf.write(l);
      }
    }
    return buf.toString();
  }

  List<String> _splitItems(String segment) {
    if (segment.isEmpty) return [];
    // Parantez içini koruyacağız: önce normal ayır
    final parts = segment.split(RegExp(r'[;,•·]'));
    final out = <String>[];
    for (final p in parts) {
      final s = p.trim();
      if (s.isEmpty) continue;
      // İçinde çok virgül varsa tekrar ince parçalara böl ama parantez içini bozma
      out.addAll(_splitByCommaRespectParentheses(s));
    }
    return out.map((e)=> e.trim()).where((e)=>e.isNotEmpty).toList();
  }

  List<String> _splitByCommaRespectParentheses(String s) {
    final result = <String>[];
    final buf = StringBuffer();
    int depth = 0;
    for (int i=0;i<s.length;i++){
      final ch = s[i];
      if (ch == '(') depth++;
      else if (ch == ')') depth = depth>0?depth-1:0;
      if (ch == ',' && depth == 0) {
        final seg = buf.toString().trim();
        if (seg.isNotEmpty) result.add(seg);
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    final last = buf.toString().trim();
    if (last.isNotEmpty) result.add(last);
    return result;
  }

  Iterable<String> _candidateTokens(String normItem) sync* {
    for (final part in normItem.split(RegExp(r'[\s/]+'))) {
      var t = part.trim();
      if (t.isEmpty) continue;
      t = t.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (t.isEmpty) continue;
      if (t.length < 2) continue;
      yield t;
      // Stem
      final st = roughStem(t);
      if (st.length >=3 && st != t) yield st;
    }
  }

  String? _mapCanonical(String token) {
    final lower = token;
    // Önce e-code
    if (IngredientSynonyms.isECode(lower)) {
      final c = IngredientSynonyms.eCodeToCanonical[lower];
      if (c != null) return c;
    }
    // Doğrudan canonical?
    if (IngredientSynonyms.synonyms.containsKey(lower)) return lower;
    // Synonym map içinde?
    for (final entry in IngredientSynonyms.synonyms.entries) {
      if (entry.value.contains(lower)) return entry.key;
    }
    return null;
  }

  double _baseVariantScore(String variant, String canonical) {
    if (variant == canonical) return 1.0;
    if (IngredientSynonyms.isECode(variant)) return 0.9;
    if (IngredientSynonyms.synonyms[canonical]?.contains(variant) == true) return 0.8;
    return 0.6;
  }

  String? _fuzzyCanonical(String token, ExtractionConfig cfg) {
    if (!cfg.enableFuzzy) return null;
    String? best;
    int bestDist = cfg.fuzzyDistance+1;

    bool acceptable(int dist, int len) =>
        dist <= cfg.fuzzyDistance &&
        dist <= (len * cfg.fuzzyRel).ceil();

    // Canonical + synonyms havuzu
    for (final entry in IngredientSynonyms.synonyms.entries) {
      final candCanon = entry.key;
      final distCanon = levenshtein(token, candCanon, max: cfg.fuzzyDistance);
      if (distCanon < bestDist && acceptable(distCanon, candCanon.length)) {
        bestDist = distCanon;
        best = candCanon;
      }
      for (final syn in entry.value) {
        final d = levenshtein(token, syn, max: cfg.fuzzyDistance);
        if (d < bestDist && acceptable(d, syn.length)) {
          bestDist = d;
          best = candCanon;
        }
      }
    }
    return best;
  }

  double _combineScores(double oldScore, double newScore) {
    if (oldScore == 0) return newScore;
    // Log-based smooth max
    return max(oldScore, newScore) + (min(oldScore, newScore) * 0.15);
  }
}

class _Accum {
  double score = 0;
  final List<String> lines = [];
  final Set<String> variants = {};
}