class SimpleNormalize {
  static const Map<String,String> _stripMap = {
    'ç':'c','Ç':'C','ğ':'g','Ğ':'G','ı':'i','İ':'I','ö':'o','Ö':'O','ş':'s','Ş':'S','ü':'u','Ü':'U'
  };

  static String basic(String s) {
    s = s.trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  static String lowerAscii(String s) {
    s = s.toLowerCase();
    final sb = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      sb.write(_stripMap[ch] ?? ch);
    }
    return sb.toString();
  }

  static List<String> tokenize(String s) {
    if (s.isEmpty) return const [];
    return s
        .split(RegExp(r'[\s\-/]+'))
        .map((e)=> e.replaceAll(RegExp(r'[^a-zA-Z0-9çÇğĞıİöÖşŞüÜ]'), ''))
        .where((e)=> e.length >= 2)
        .toList();
  }
}