import 'package:characters/characters.dart';

String prettifyLabel(String? raw, {bool titleCase = false}) {
  if (raw == null) return '';
  var s = raw.trim().replaceAll('_', ' ');
  if (s.isEmpty) return s;
  if (titleCase) {
    final parts = s.split(RegExp(r'\s+'));
    s = parts.map((w) {
      if (w.isEmpty) return w;
      if (w == w.toUpperCase()) return w;
      final first = w.characters.first;
      final rest = w.characters.skip(1).join();
      return first.toUpperCase() + rest.toLowerCase();
    }).join(' ');
  }
  return s;
}

String normalizeForSearch(String input) =>
    input.toLowerCase().replaceAll('_', ' ').replaceAll(RegExp(r'[^a-z0-9ğüşöçıİ ]', caseSensitive: false), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();