import 'package:flutter/foundation.dart';
import '../models/ingredient.dart';
import '../data/ingredient_service.dart';
import '../services/favorites_service.dart';
import '../services/ingredient_index_service.dart';

enum HomeStatus { idle, loading, ready, error }

class HomeViewModel extends ChangeNotifier {
  final _ingredientService = IngredientService();
  final _favoritesService = FavoritesService();
  final IngredientIndexService indexService;

  HomeStatus status = HomeStatus.idle;
  String? error;
  List<Ingredient> all = [];
  List<Ingredient> highRiskTop = [];
  List<String> recentScanIds = []; // persist etmek istersen SharedPreferences ile saklayabilirsin
  bool initialized = false;

  HomeViewModel({required this.indexService});

  Future<void> init() async {
    if (initialized) return;
    status = HomeStatus.loading;
    notifyListeners();
    try {
      await _favoritesService.init();
      all = await _ingredientService.loadAll();
      indexService.buildIndex(all);
      highRiskTop = _computeHighRisk();
      status = HomeStatus.ready;
      initialized = true;
    } catch (e) {
      error = e.toString();
      status = HomeStatus.error;
    }
    notifyListeners();
  }

  List<Ingredient> _computeHighRisk() {
    final copy = List<Ingredient>.from(all);
    copy.sort((a, b) {
      int levelRank(String l) {
        switch (l) {
          case 'red':
            return 3;
          case 'yellow':
            return 2;
          case 'green':
            return 1;
          default:
            return 0;
        }
      }
      final lr = levelRank(b.risk.riskLevel).compareTo(levelRank(a.risk.riskLevel));
      if (lr != 0) return lr;
      return b.risk.riskScore.compareTo(a.risk.riskScore);
    });
    return copy.take(5).toList();
  }

  List<Ingredient> get favorites => all
      .where((i) => _favoritesService.isFavorite(i.id))
      .toList();

  bool isFavorite(String id) => _favoritesService.isFavorite(id);

  Future<void> toggleFavorite(String id) async {
    await _favoritesService.toggle(id);
    notifyListeners();
  }

  void addRecentScan(List<Ingredient> matched) {
    for (final ing in matched) {
      recentScanIds.remove(ing.id);
      recentScanIds.insert(0, ing.id);
    }
    if (recentScanIds.length > 10) {
      recentScanIds = recentScanIds.take(10).toList();
    }
    notifyListeners();
  }

  List<Ingredient> get recentScans =>
      recentScanIds.map((id) => all.firstWhere((i) => i.id == id, orElse: () => all.first)).toList();
}