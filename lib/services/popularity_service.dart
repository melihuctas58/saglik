class PopularityService {
  static final PopularityService instance = PopularityService._();
  PopularityService._();

  final Map<String, int> _counts = {};

  String _deriveKey(dynamic item, String Function(dynamic)? keyFn) {
    if (keyFn != null) return keyFn(item);
    // Varsayılan: core.primaryName
    try {
      final n = (item.core?.primaryName ?? '').toString().toLowerCase();
      return n;
    } catch (_) {
      return item.hashCode.toString();
    }
  }

  void bump(dynamic item, {String Function(dynamic)? keyFn}) {
    final k = _deriveKey(item, keyFn);
    _counts[k] = (_counts[k] ?? 0) + 1;
  }

  void bumpMany(Iterable items, {String Function(dynamic)? keyFn}) {
    for (final it in items) {
      bump(it, keyFn: keyFn);
    }
  }

  int count(dynamic item, {String Function(dynamic)? keyFn}) {
    final k = _deriveKey(item, keyFn);
    return _counts[k] ?? 0;
  }

  List<T> topN<T>(List<T> universe, int n, {String Function(dynamic)? keyFn}) {
    final list = List<T>.from(universe);
    list.sort((a, b) =>
        count(b, keyFn: keyFn).compareTo(count(a, keyFn: keyFn)));
    return list.take(n).toList();
  }

  Map<String, int> snapshot() => Map.unmodifiable(_counts);

  void reset() => _counts.clear();
}