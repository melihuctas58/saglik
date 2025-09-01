import 'dart:math';

String stripDiacritics(String input) {
  const Map<String, String> map = {
    'ç': 'c',
    'Ç': 'c',
    'ğ': 'g',
    'Ğ': 'g',
    'ı': 'i',
    'İ': 'i',
    'ö': 'o',
    'Ö': 'o',
    'ş': 's',
    'Ş': 's',
    'ü': 'u',
    'Ü': 'u'
  };
  final sb = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    sb.write(map[ch] ?? ch);
  }
  return sb.toString();
}

String normalizePhrase(String s) {
  s = stripDiacritics(s.toLowerCase());
  // "E 330" veya "E-330" → "e330"
  s = s.replaceAllMapped(RegExp(r'e\s*[- ]?\s*(\d{3}[a-z]?)'),
      (m) => 'e${m.group(1)}');
  s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

List<String> tokenize(String phrase) {
  if (phrase.isEmpty) return const [];
  return phrase.split(' ').where((e) => e.isNotEmpty).toList();
}

String joinTokens(List<String> tokens, int i, int len) {
  return tokens.sublist(i, i + len).join(' ');
}

double safeLog(double x) => x <= 0 ? 0.0 : log(x);
