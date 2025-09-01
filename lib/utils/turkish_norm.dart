String stripDiacritics(String input) {
  const map = {
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
    'Ü': 'u',
  };
  final sb = StringBuffer();
  for (final ch in input.runes) {
    final s = String.fromCharCode(ch);
    sb.write(map[s] ?? s);
  }
  return sb.toString();
}

String basicNormalize(String s) {
  s = stripDiacritics(s.toLowerCase().trim());
  s = s.replaceAll(RegExp(r'[^\sa-z0-9,;:.()\-/]'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s.trim();
}

String roughStem(String token) {
  var t = token;
  for (final suf in [
    'lari',
    'leri',
    'lar',
    'ler',
    'nin',
    'nın',
    'nun',
    'nün',
    'in',
    'ın',
    'un',
    'ün',
    'si',
    'sı',
    'su',
    'sü',
    'i',
    'ı',
    'u',
    'ü'
  ]) {
    if (t.endsWith(suf) && t.length - suf.length >= 3) {
      t = t.substring(0, t.length - suf.length);
      break;
    }
  }
  return t;
}