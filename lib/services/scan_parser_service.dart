import '../utils/text_format.dart';

/// Fotoğraflı taramadan gelen tam metni parçalar.
class ScanParserService {
  static final _sectionMarkers = <RegExp>[
    RegExp(r'\bİÇİNDEKİLER\b', caseSensitive: false),
    RegExp(r'\bICINDEKILER\b', caseSensitive: false),
    RegExp(r'\bİcindekiler\b', caseSensitive: false),
    RegExp(r'\bINGREDIENTS\b', caseSensitive: false),
    RegExp(r'\bCONTENT(S)?\b', caseSensitive: false),
  ];

  /// Geri dönen:
  /// tokens: filtrelenmiş tek kelime token listesi
  /// phrases: virgül / noktalı virgül / satıra göre parçalanmış candidate ifadeler
  ParseResult parse(String fullText) {
    // Normalize satır sonları
    var text = fullText.replaceAll('\r', '\n');

    // 1. İçindekiler segmenti tespiti
    String segment = _extractSegment(text);

    // 2. Küçült + bazı işaretleri boşluk / ayırıcıya çevir
    final cleaned = segment
        .replaceAll(RegExp(r'[\t]+'), ' ')
        .replaceAll(RegExp(r'[•·]+'), ',')
        .replaceAll(RegExp(r'[\u00AD]'), '') // soft hyphen
        .replaceAll(RegExp(r'[:|=]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // 3. Phrases: virgül / ; / \n ayır
    final phraseRaw = segment.split(RegExp(r'[,\n;]+'))
      ..removeWhere((p) => p.trim().isEmpty);

    final phrases = phraseRaw
        .map((p) => normalizeForSearch(p))
        .where((p) => p.isNotEmpty)
        .toList();

    // 4. Tekil tokens
    final tokenCandidates = normalizeForSearch(cleaned)
        .split(' ')
        .where((t) => t.length >= 3)
        .toList();

    // 5. Çok kısa veya tamamen rakam olanları at
    final filteredTokens = tokenCandidates
        .where((t) => RegExp(r'[a-zğüşöçı]').hasMatch(t))
        .toList();

    return ParseResult(tokens: filteredTokens, phrases: phrases);
  }

  String _extractSegment(String text) {
    for (final r in _sectionMarkers) {
      final m = r.firstMatch(text);
      if (m != null) {
        // Marker'dan sonraki 600 karakter (çok uzun olmasın)
        final start = m.end;
        final rest = text.substring(start);
        // İlk çift satır boşluğu veya "Besin Değeri" gibi bir başka bölüm gelince kes.
        final cutIndex = _firstIndexOfAny(rest, [
          RegExp(r'\bBESİN\b', caseSensitive: false),
          RegExp(r'\bNUTRITION', caseSensitive: false),
          RegExp(r'\bENERJİ\b', caseSensitive: false),
        ]);
        final slice = (cutIndex == -1 ? rest : rest.substring(0, cutIndex));
        return slice.length > 600 ? slice.substring(0, 600) : slice;
      }
    }
    // Marker yoksa fallback: tüm metnin ilk 800 karakteri
    return text.length > 800 ? text.substring(0, 800) : text;
  }

  int _firstIndexOfAny(String s, List<RegExp> regs) {
    int min = -1;
    for (final r in regs) {
      final m = r.firstMatch(s);
      if (m != null) {
        if (min == -1 || m.start < min) {
          min = m.start;
        }
      }
    }
    return min;
  }
}

class ParseResult {
  final List<String> tokens;
  final List<String> phrases;
  ParseResult({required this.tokens, required this.phrases});
}