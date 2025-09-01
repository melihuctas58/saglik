int levenshtein(String s, String t, {int max = 3}) {
  if ((s.length - t.length).abs() > max) return max + 1;
  final m = s.length;
  final n = t.length;
  if (m == 0) return n;
  if (n == 0) return m;
  List<int> prev = List<int>.generate(n + 1, (j) => j);
  List<int> curr = List.filled(n + 1, 0);
  for (int i = 1; i <= m; i++) {
    curr[0] = i;
    int rowMin = curr[0];
    final sc = s.codeUnitAt(i - 1);
    for (int j = 1; j <= n; j++) {
      final tc = t.codeUnitAt(j - 1);
      final cost = (sc == tc) ? 0 : 1;
      final del = prev[j] + 1;
      final ins = curr[j - 1] + 1;
      final sub = prev[j - 1] + cost;
      int v = del;
      if (ins < v) v = ins;
      if (sub < v) v = sub;
      curr[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > max) return max + 1;
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[n];
}