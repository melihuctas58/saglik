import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ingredient.dart';
import '../data/ingredient_service.dart';
import '../utils/text_format.dart'; // <-- normalizeForSearch & prettifyLabel burada

enum IngredientStatus { idle, loading, ready, error }

class IngredientViewModel extends ChangeNotifier {
  IngredientStatus status = IngredientStatus.idle;
  String? error;
  List<Ingredient> all = [];
  List<Ingredient> filtered = [];

  final _service = IngredientService();
  Timer? _debounce;

  Future<void> init() async {
    status = IngredientStatus.loading;
    notifyListeners();
    try {
      all = await _service.loadAll();
      filtered = List.of(all);
      status = IngredientStatus.ready;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      status = IngredientStatus.error;
      notifyListeners();
    }
  }

  void search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final normQuery = normalizeForSearch(q);
      if (normQuery.isEmpty) {
        filtered = List.of(all);
      } else {
        filtered = all.where((ing) {
          final names = ing.core.names;

          bool synonymHit = false;
          final syn = names['synonyms'];
          if (syn is List) {
            synonymHit = syn.any((s) =>
                normalizeForSearch(s.toString()).contains(normQuery));
          }

          bool match(String v) =>
              normalizeForSearch(v).contains(normQuery);

          return match(ing.core.primaryName) ||
              match(names['tr']?.toString() ?? '') ||
              match(names['en']?.toString() ?? '') ||
              synonymHit ||
              match(ing.identifiers.eNumber ?? '') ||
              match(ing.core.category) ||
              match(ing.core.subcategory) ||
              match(ing.classification.originType) ||
              ing.usage.whereUsed.any(match) ||
              ing.usage.commonRoles.any(match) ||
              ing.health.healthFlags.any(match);
        }).toList();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}