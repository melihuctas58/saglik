// Kaynak: Kullanıcının sağladığı güçlü çıkarım algoritması (birebir).
import 'dart:ui' show Rect;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/ingredient.dart';
import '../utils/text_normalizer.dart';

/* =============== EŞİKLER =============== */

const int kSingleTokenMinLen = 3;         // tek-kelime için min uzunluk
const double kMultiTokenCoverage = 0.80;  // çok kelimeli isimlerde kapsama
const double kAcceptScoreOcr = 0.78;      // OCR tabanlı nihai skor eşiği
const double kAcceptScoreText = 0.78;     // Fallback (ham metin) eşiği

/* =============== KAMU API =============== */

// OCR objesiyle satır/konum tabanlı çıkarım (öncelikli)
List<Ingredient> extractIngredientsFromOcr(
  RecognizedText ocr,
  List<Ingredient> all,
) {
  final lines = _flattenLines(ocr);
  final header = _findHeaderLine(lines);
  final region = _buildRegion(lines, header);
  final candidates = _buildLineCandidates(region);
  final eNumbers = _collectENumbersFromRegion(region);

  final seen = <String>{};
  final scored = <_ScoredIng>[];

  for (final ing in all) {
    final names = _collectAllNames(ing);
    if (names.isEmpty) continue;

    // Öncelik setleri
    final primary = (ing.core.primaryName).toLowerCase().trim();
    final synListDyn = ing.core.names['synonyms'];
    final synSet = <String>{
      if (synListDyn is List) ...synListDyn.map((e) => e.toString().toLowerCase().trim()),
    };

    // E-numarası ile direkt eşleşme
    final eNorm = _normalizeENumber(ing.identifiers.eNumber);
    if (eNorm != null && eNorm.isNotEmpty && eNumbers.contains(eNorm)) {
      if (seen.add(ing.core.primaryName.toLowerCase())) {
        scored.add(_ScoredIng(ing, 1.0));
      }
      continue;
    }

    // İsim/alias bazlı skor
    double best = 0.0;
    for (final name in names) {
      final nameNorm = normalizeForSearch(name);
      if (nameNorm.isEmpty) continue;

      final isPrimary = name.toLowerCase().trim() == primary && primary.isNotEmpty;
      final isSynonym = synSet.contains(name.toLowerCase().trim());

      final nameTokensOrig = nameNorm.split(' ').where((t) => t.isNotEmpty).toList();
      if (nameTokensOrig.isEmpty) continue;

      final tokensForMatch = _filterTokensMinLen(nameTokensOrig, minLen: 3);
      final usableTokens = tokensForMatch.isNotEmpty ? tokensForMatch : nameTokensOrig;

      double localBest = 0.0;
      for (final cand in candidates) {
        final w = cand.headerProxWeight;

        // a) Tek kelime: min uzunluk ve tam token varlığı
        if (usableTokens.length == 1) {
          final tok = usableTokens.first;
          if (tok.length >= kSingleTokenMinLen && cand.tokenSet.contains(tok)) {
            localBest = (1.0 * w).clamp(0.0, 1.0);
            break;
          }
          continue;
        }

        // b) Çok kelimeli: satır içinde tam ifade
        if (_containsPhrase(cand.norm, nameNorm)) {
          localBest = (1.0 * w).clamp(0.0, 1.0);
          break;
        }

        // c) Token kapsaması
        final inter = _intersectionCount(cand.tokenSet, usableTokens);
        final ratioName = inter / usableTokens.length;
        final ratioCand = inter / (cand.tokenSet.isEmpty ? 1 : cand.tokenSet.length);
        double score = ((ratioName * 0.9) + (ratioCand * 0.1)) * w;

        if (inter >= 2 && ratioName >= kMultiTokenCoverage) {
          score = (score < 0.9 ? 0.9 * w : score).clamp(0.0, 1.0);
        }

        if (score > localBest) localBest = score;
      }

      // Öncelik: primary_name > synonyms > diğer
      final nameWeight = isPrimary ? 1.12 : (isSynonym ? 1.05 : 1.0);
      localBest = (localBest * nameWeight).clamp(0.0, 1.0);

      if (localBest > best) best = localBest;
    }

    if (best >= kAcceptScoreOcr) {
      if (seen.add(ing.core.primaryName.toLowerCase())) {
        scored.add(_ScoredIng(ing, best));
      }
    }
  }

  scored.sort((a, b) => b.score.compareTo(a.score));
  return scored.map((e) => e.ing).toList();
}

// Ham metin fallback (başlık bulunamazsa)
List<Ingredient> extractIngredients(String raw, List<Ingredient> all) {
  final section = _extractIngredientsSection(raw);
  final source = section.isNotEmpty ? section : raw;
  final candidates = _buildTextCandidates(source);
  final eNumbers = _collectENumbers(raw);

  final seen = <String>{};
  final out = <Ingredient>[];

  for (final ing in all) {
    final names = _collectAllNames(ing);
    if (names.isEmpty) continue;

    final primary = (ing.core.primaryName).toLowerCase().trim();
    final synListDyn = ing.core.names['synonyms'];
    final synSet = <String>{
      if (synListDyn is List) ...synListDyn.map((e) => e.toString().toLowerCase().trim()),
    };

    final eNorm = _normalizeENumber(ing.identifiers.eNumber);
    if (eNorm != null && eNorm.isNotEmpty && eNumbers.contains(eNorm)) {
      if (seen.add(ing.core.primaryName.toLowerCase())) out.add(ing);
      continue;
    }

    double best = 0.0;
    for (final name in names) {
      final nameNorm = normalizeForSearch(name);
      if (nameNorm.isEmpty) continue;

      final isPrimary = name.toLowerCase().trim() == primary && primary.isNotEmpty;
      final isSynonym = synSet.contains(name.toLowerCase().trim());

      final nameTokensOrig = nameNorm.split(' ').where((t) => t.isNotEmpty).toList();
      if (nameTokensOrig.isEmpty) continue;

      final tokensForMatch = _filterTokensMinLen(nameTokensOrig, minLen: 3);
      final usableTokens = tokensForMatch.isNotEmpty ? tokensForMatch : nameTokensOrig;

      double localBest = 0.0;
      for (final cand in candidates) {
        if (usableTokens.length == 1) {
          final tok = usableTokens.first;
          if (tok.length >= kSingleTokenMinLen && cand.tokenSet.contains(tok)) {
            localBest = 1.0;
            break;
          }
          continue;
        }

        if (_containsPhrase(cand.norm, nameNorm)) {
          localBest = 1.0;
          break;
        }

        final inter = _intersectionCount(cand.tokenSet, usableTokens);
        final ratioName = inter / usableTokens.length;
        final ratioCand = inter / (cand.tokenSet.isEmpty ? 1 : cand.tokenSet.length);
        double score = (ratioName * 0.9) + (ratioCand * 0.1);

        if (inter >= 2 && ratioName >= kMultiTokenCoverage) {
          score = score < 0.9 ? 0.9 : score;
        }

        if (score > localBest) localBest = score;
      }

      final nameWeight = isPrimary ? 1.12 : (isSynonym ? 1.05 : 1.0);
      localBest = (localBest * nameWeight).clamp(0.0, 1.0);

      if (localBest > best) best = localBest;
    }

    if (best >= kAcceptScoreText) {
      if (seen.add(ing.core.primaryName.toLowerCase())) out.add(ing);
    }
  }

  return out;
}

/* =============== İSİM/ALIAS TOPLAMA =============== */

List<String> _collectAllNames(Ingredient ing) {
  final set = <String>{};

  // 1) Primary
  if (ing.core.primaryName.isNotEmpty) set.add(ing.core.primaryName);

  // 2) core.names.{tr,en,synonyms}
  try {
    final names = ing.core.names;
    if (names.isNotEmpty) {
      final tr = names['tr'];
      final en = names['en'];
      final syn = names['synonyms'];
      if (tr is String && tr.isNotEmpty) set.add(tr);
      if (en is String && en.isNotEmpty) set.add(en);
      if (syn is List) {
        for (final x in syn) {
          if (x is String && x.isNotEmpty) set.add(x);
        }
      }
    }
  } catch (_) {}

  // 3) consumer.labelNamesAlt
  try {
    final alt1 = ing.consumer.labelNamesAlt;
    for (final x in alt1) {
      if (x.isNotEmpty) set.add(x);
    }
  } catch (_) {}

  return set.toList();
}

/* =============== OCR Yardımcıları =============== */

class _OcrLine {
  final String text;
  final String norm;
  final List<String> tokens;
  final Rect? box;
  _OcrLine(this.text, this.norm, this.tokens, this.box);

  double get top => box?.top ?? 0;
  double get bottom => box?.bottom ?? 0;
  double get centerY => (top + bottom) / 2.0;
}

List<_OcrLine> _flattenLines(RecognizedText ocr) {
  final out = <_OcrLine>[];
  for (final block in ocr.blocks) {
    for (final line in block.lines) {
      final norm = normalizeForSearch(line.text);
      final tokens = norm.split(' ').where((w) => w.isNotEmpty).toList();
      out.add(_OcrLine(line.text, norm, tokens, line.boundingBox));
    }
  }
  return out;
}

final Set<String> _headerKeys = {
  'içindekiler', 'icerik', 'ingredients', 'composition', 'zutaten',
  'ingrédients', 'ingredientes', 'ingredienti', 'состав', 'malzemeler',
};

final Set<String> _sectionTailKeys = {
  'allergen', 'alerjen', 'nutrition', 'besin', 'saklama', 'storage',
  'uyarı', 'warning', 'kullanım', 'usage', 'net', 'miktar',
};

_OcrLine? _findHeaderLine(List<_OcrLine> lines) {
  for (final l in lines) {
    final low = l.text.toLowerCase();
    for (final k in _headerKeys) {
      if (low.contains(k)) return l;
    }
  }
  return null;
}

class _Region {
  final List<_OcrLine> lines;
  final double headerY;
  final double endY;
  _Region(this.lines, this.headerY, this.endY);
}

_Region _buildRegion(List<_OcrLine> lines, _OcrLine? header) {
  if (lines.isEmpty) return _Region([], 0, 0);
  if (header == null) {
    return _Region(lines, 0, lines.last.bottom);
  }

  final headerY = header.bottom;
  double endY = lines.isNotEmpty ? lines.last.bottom : headerY + 1000;
  for (final l in lines) {
    if (l.top <= headerY) continue;
    final low = l.text.toLowerCase();
    for (final t in _sectionTailKeys) {
      if (low.contains(t)) {
        endY = l.top;
        break;
      }
    }
    if (endY != lines.last.bottom) break;
  }

  final regionLines = lines.where((l) => l.centerY > headerY && l.top < endY).toList();
  return _Region(regionLines, headerY, endY);
}

class _Cand {
  final String norm;             // satır/n-gram normalize metin
  final List<String> tokens;     // tüm tokenlar (min 3 uzunluk filtresinden geçmiş)
  final Set<String> tokenSet;    // token seti
  final double headerProxWeight; // başlığa yakınlık ağırlığı (0.6..1.0)
  _Cand(this.norm, this.tokens, this.headerProxWeight) : tokenSet = tokens.toSet();
}

List<_Cand> _buildLineCandidates(_Region region) {
  if (region.lines.isEmpty) return const [];
  final startY = region.headerY;
  final endY = region.endY <= startY ? (startY + 1) : region.endY;
  final height = (endY - startY).abs() + 1;

  final out = <_Cand>[];
  for (final l in region.lines) {
    if (l.norm.isEmpty) continue;

    // Tokenları uzunluğa göre filtrele (min 3)
    final filteredTokens = _filterTokensMinLen(l.tokens, minLen: 3);
    if (filteredTokens.isEmpty) continue;

    // Yakınlık ağırlığı: başlığa yakın 1.0, sona doğru 0.6
    final dy = (l.centerY - startY).clamp(0.0, height);
    final w = (1.0 - (dy / height) * 0.4).clamp(0.6, 1.0);

    // Satırın kendisi
    out.add(_Cand(filteredTokens.join(' '), filteredTokens, w));

    // Satır içi 2..4-gram
    final nMax = filteredTokens.length < 4 ? filteredTokens.length : 4;
    for (int n = 2; n <= nMax; n++) {
      for (int i = 0; i + n <= filteredTokens.length; i++) {
        final gram = filteredTokens.sublist(i, i + n);
        if (gram.isEmpty) continue;
        out.add(_Cand(gram.join(' '), gram, w));
      }
    }
  }

  if (out.length > 1500) {
    return out.sublist(0, 1500);
  }
  return out;
}

Set<String> _collectENumbersFromRegion(_Region region) {
  final buf = StringBuffer();
  for (final l in region.lines) {
    buf.write(l.text);
    buf.write(' ');
  }
  return _collectENumbers(buf.toString());
}

/* =============== Metin tabanlı fallback yardımcıları =============== */

class _TextCand {
  final String norm;
  final List<String> tokens;
  final Set<String> tokenSet;
  _TextCand(this.norm, this.tokens) : tokenSet = tokens.toSet();
}

List<_TextCand> _buildTextCandidates(String source) {
  final replaced = source
      .replaceAll('\n', ',')
      .replaceAll('•', ',')
      .replaceAll('·', ',')
      .replaceAll('–', ' - ')
      .replaceAll('-', ' - ');
  final parts = replaced.split(RegExp(r'[;,()\[\]\{\}|•·]+'));
  final list = <_TextCand>[];

  for (var p in parts) {
    final t = p.trim();
    if (t.isEmpty) continue;

    final norm = normalizeForSearch(t);
    if (norm.isEmpty) continue;

    final tokens = norm.split(' ').where((w) => w.isNotEmpty).toList();
    final filteredTokens = _filterTokensMinLen(tokens, minLen: 3);
    if (filteredTokens.isEmpty) continue;

    if (filteredTokens.length == 1) {
      if (filteredTokens.first.length >= kSingleTokenMinLen) {
        list.add(_TextCand(filteredTokens.join(' '), filteredTokens));
      }
      continue;
    }

    list.add(_TextCand(filteredTokens.join(' '), filteredTokens));

    final nMax = filteredTokens.length < 4 ? filteredTokens.length : 4;
    for (int n = 2; n <= nMax; n++) {
      for (int i = 0; i + n <= filteredTokens.length; i++) {
        final gram = filteredTokens.sublist(i, i + n);
        if (gram.isEmpty) continue;
        list.add(_TextCand(gram.join(' '), gram));
      }
    }
  }

  if (list.length > 1200) return list.sublist(0, 1200);
  return list;
}

// İçindekiler başlığından sonra gelen kısmı ayıkla (fallback)
String _extractIngredientsSection(String raw) {
  final lower = raw.toLowerCase();
  const heads = <String>[
    'içindekiler', 'icerik', 'ingredients', 'composition', 'zutaten',
    'ingrédients', 'ingredientes', 'ingredienti', 'состав', 'malzemeler',
  ];
  int start = -1;
  for (final h in heads) {
    final i = lower.indexOf(h);
    if (i != -1) {
      start = i + h.length;
      break;
    }
  }
  if (start == -1) return '';

  const tails = <String>[
    '\n\n', 'allergen', 'alerjen', 'nutrition', 'besin', 'saklama',
    'storage', 'uyarı', 'warning', 'kullanım', 'usage', 'net', 'miktar',
  ];
  var end = raw.length;
  for (final t in tails) {
    final i = lower.indexOf(t, start);
    if (i != -1) {
      end = i;
      break;
    }
  }

  final slice = raw.substring(start, end);
  return slice.length > 4000 ? slice.substring(0, 4000) : slice;
}

/* =============== Ortak yardımcılar =============== */

List<String> _filterTokensMinLen(List<String> tokens, {int minLen = 3}) {
  final out = <String>[];
  for (final t in tokens) {
    if (t.length < minLen) continue;
    out.add(t);
  }
  return out;
}

bool _containsPhrase(String haystack, String needle) {
  if (needle.length < 3) return false;
  final h = ' $haystack ';
  final n = ' $needle ';
  return h.contains(n);
}

int _intersectionCount(Set<String> candSet, List<String> nameTokens) {
  var c = 0;
  for (final t in nameTokens) {
    if (candSet.contains(t)) c++;
  }
  return c;
}

Set<String> _collectENumbers(String raw) {
  final re = RegExp(r'\bE[-\s]?(\d{3,4}[a-zA-Z]?)\b', caseSensitive: false);
  final set = <String>{};
  for (final m in re.allMatches(raw)) {
    final g = m.group(1);
    final norm = _normalizeENumber(g);
    if (norm != null && norm.isNotEmpty) set.add(norm);
  }
  return set;
}

// "E300", "E-300", "e 300a" -> "300A"
String? _normalizeENumber(String? e) {
  if (e == null) return null;
  final up = e.toUpperCase();
  final only = up.replaceAll(RegExp(r'[^0-9A-Z]'), '');
  return only.startsWith('E') ? only.substring(1) : only;
}

class _ScoredIng {
  final Ingredient ing;
  final double score;
  _ScoredIng(this.ing, this.score);
}