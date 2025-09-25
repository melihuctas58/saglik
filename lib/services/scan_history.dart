import 'package:flutter/foundation.dart';
import '../models/ingredient.dart';

class ScanRecord {
  final DateTime timestamp;
  final List<String> ingredientIds;
  final String rawText;

  ScanRecord({
    required this.timestamp,
    required this.ingredientIds,
    required this.rawText,
  });
}

class ScanHistoryService extends ChangeNotifier {
  ScanHistoryService._();
  static final ScanHistoryService instance = ScanHistoryService._();

  final List<ScanRecord> _records = [];

  List<ScanRecord> get records => List.unmodifiable(_records);

  void addScan(List<Ingredient> ingredients, String rawText) {
    final ids = <String>[];
    for (final ing in ingredients) {
      final id = _safeIdOf(ing);
      if (id.isNotEmpty) ids.add(id);
    }
    if (ids.isEmpty) return;
    _records.insert(
      0,
      ScanRecord(
        timestamp: DateTime.now(),
        ingredientIds: ids,
        rawText: rawText,
      ),
    );
    notifyListeners();
  }

  void clear() {
    _records.clear();
    notifyListeners();
  }

  // Ingredient id fallback: id -> slug -> primaryName
  String _safeIdOf(Ingredient ing) {
    try {
      // ignore: avoid_dynamic_calls
      final dyn = ing as dynamic;
      final id = dyn.id;
      if (id is String && id.isNotEmpty) return id;
      final slug = dyn.slug;
      if (slug is String && slug.isNotEmpty) return slug;
    } catch (_) {}
    final name = ing.core.primaryName;
    return name.isNotEmpty ? name : '';
  }
}