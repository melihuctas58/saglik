import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ingredient.dart';
import 'cloud_scan_history.dart'; // kendi projenin yoluna göre düzelt

class ScanRecord {
  final DateTime timestamp;
  final List<Ingredient> ingredients;
  final String? imagePath;
  final String? rawText;

  ScanRecord({
    required this.timestamp,
    required this.ingredients,
    this.imagePath,
    this.rawText,
  });
}

class ScanHistoryService extends ChangeNotifier {
  ScanHistoryService._();
  static final ScanHistoryService instance = ScanHistoryService._();

  static const _prefsKey = 'scan_history_v1';

  final List<ScanRecord> _records = [];
  bool _inited = false;

  // Senkron sırasında buluta yazmayı kapatma bayrağı
  bool _suppressCloudWrites = false;
  void beginSync() => _suppressCloudWrites = true;
  void endSync() => _suppressCloudWrites = false;

  List<ScanRecord> get records => List.unmodifiable(_records);

  // Uygulama açılışında, tüm ingredient listesi yüklendikten sonra çağır.
  Future<void> init(List<Ingredient> all) async {
    if (_inited) return;
    _inited = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) {
        notifyListeners();
        return;
      }

      final List list = jsonDecode(raw) as List;
      final idMap = _buildIdMap(all);

      _records.clear();
      for (final e in list) {
        final m = e as Map<String, dynamic>;
        final ts = DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime.now();
        final ids = (m['ingredientIds'] as List<dynamic>? ?? []).map((x) => x.toString()).toList();
        final ings = ids.map((id) => idMap[id]).whereType<Ingredient>().toList();
        _records.add(ScanRecord(
          timestamp: ts,
          ingredients: ings,
          imagePath: (m['imagePath'] as String?) ?? '',
          rawText: (m['rawText'] as String?) ?? '',
        ));
      }
      notifyListeners();
    } catch (_) {
      // ignore parse errors
      notifyListeners();
    }
  }

  Future<void> add(List<Ingredient> ings, {String? imagePath, String? rawText}) async {
    _records.insert(
      0,
      ScanRecord(
        timestamp: DateTime.now(),
        ingredients: List<Ingredient>.from(ings),
        imagePath: imagePath,
        rawText: rawText,
      ),
    );
    notifyListeners();
    await _saveToPrefs();

    // 🌩 Bulut senkron ekleme (senkron sırasında kapatılır)
    if (!_suppressCloudWrites) {
      try {
        final names = ings.map((i) => i.core.primaryName).toList();
        await CloudScanHistory.instance.addScan(
          ingredientNames: names,
          imageUrl: imagePath,
          rawText: rawText,
          localTime: DateTime.now(),
        );
      } catch (_) {
        // buluta yazılamazsa sessiz geç
      }
    }
  }

  Future<void> clear() async {
    _records.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  // ---------- Helpers ----------

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _records.map((r) {
        return {
          'timestamp': r.timestamp.toIso8601String(),
          'ingredientIds': r.ingredients.map(_safeIdOf).where((id) => id.isNotEmpty).toList(),
          'imagePath': r.imagePath ?? '',
          'rawText': r.rawText ?? '',
        };
      }).toList();
      await prefs.setString(_prefsKey, jsonEncode(data));
    } catch (_) {
      // ignore write errors
    }
  }

  Map<String, Ingredient> _buildIdMap(List<Ingredient> all) {
    final map = <String, Ingredient>{};
    for (final ing in all) {
      final id = _safeIdOf(ing);
      if (id.isNotEmpty) {
        map[id] = ing;
      }
    }
    return map;
  }

  // Ingredient id fallback: id -> slug -> primaryName (lower)
  String _safeIdOf(Ingredient ing) {
    try {
      final dyn = ing as dynamic;
      final id = dyn.id;
      if (id is String && id.isNotEmpty) return id.toLowerCase();
      final slug = dyn.slug;
      if (slug is String && slug.isNotEmpty) return slug.toLowerCase();
    } catch (_) {}
    final name = ing.core.primaryName;
    return name.isNotEmpty ? name.toLowerCase() : '';
  }
}