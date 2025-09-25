// Basit ve güvenli normalize: küçük harf + Türkçe/aksan kaldırma + alfasayısal dışını boşluk yapma
String normalizeForSearch(String s) {
  if (s.isEmpty) return s;
  var x = s.toLowerCase();

  // Tekil ve çakışmasız harita
  final Map<String, String> map = {
    'ı': 'i', 'ğ': 'g', 'ş': 's', 'ç': 'c', 'ö': 'o', 'ü': 'u',
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u',
    'ñ': 'n', 'ý': 'y', 'ÿ': 'y',
  };
  map.forEach((k, v) => x = x.replaceAll(k, v));

  // Alfasayısal dışını boşluk yap, çoklu boşlukları tekille
  x = x.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  x = x.replaceAll(RegExp(r'\s+'), ' ').trim();
  return x;
}