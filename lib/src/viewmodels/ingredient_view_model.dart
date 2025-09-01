import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ingredient.dart';
import '../services/ingredient_service.dart';

enum IngredientStateStatus { idle, loading, ready, error }

class IngredientViewModel extends ChangeNotifier {
  IngredientStateStatus status = IngredientStateStatus.idle;
  String? errorMessage;
  List<Ingredient> all = [];
  List<Ingredient> filtered = [];

  final _service = IngredientService();
  Timer? _debounce;

  Future<void> init() async {
    status = IngredientStateStatus.loading;
    notifyListeners();
    try {
      all = await _service.loadAll();
      filtered = List.of(all);
      status = IngredientStateStatus.ready;
      notifyListeners();
    } catch (e) {
      status = IngredientStateStatus.error;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (query.trim().isEmpty) {
        filtered = List.of(all);
      } else {
        final q = query.toLowerCase();
        filtered = all.where((ing) {
          bool matchSyn = false;
          final syn = ing.core.names['synonyms'];
          if (syn is List) {
            matchSyn = syn.any((s) => s.toString().toLowerCase().contains(q));
          }
            return ing.core.primaryName.toLowerCase().contains(q) ||
                (ing.core.names['tr']?.toString().toLowerCase().contains(q) ?? false) ||
                (ing.core.names['en']?.toString().toLowerCase().contains(q) ?? false) ||
                matchSyn ||
                (ing.identifiers.eNumber ?? '').toLowerCase().contains(q) ||
                ing.core.category.toLowerCase().contains(q) ||
                ing.core.subcategory.toLowerCase().contains(q);
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