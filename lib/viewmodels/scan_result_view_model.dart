import 'package:flutter/foundation.dart';
import '../services/ingredient_advanced_match_service.dart';

class ScanResultViewModel extends ChangeNotifier {
  final AdvancedIngredientMatchService service;
  final AdvancedMatchConfig config;

  List<AdvancedIngredientMatch> matches = [];
  List<String> unknownTokens = [];

  ScanResultViewModel({
    required this.service,
    this.config = const AdvancedMatchConfig(),
  });

  void compute({
    required List<String> tokens,
    required List<String> phrases,
  }) {
    matches = service.match(
      queryTokens: tokens,
      phrases: phrases,
      config: config,
    );

    final matchedTokenUnion = <String>{};
    for (final m in matches) {
      matchedTokenUnion.addAll(m.matchedTokens);
    }
    unknownTokens = tokens
        .where((t) => !matchedTokenUnion.contains(t))
        .toSet()
        .toList();
    notifyListeners();
  }

  Map<String, List<AdvancedIngredientMatch>> groupedByRisk() {
    final map = <String, List<AdvancedIngredientMatch>>{
      'red': [],
      'yellow': [],
      'green': [],
      'other': []
    };
    for (final m in matches) {
      final r = m.ingredient.risk.riskLevel;
      (map[r] ?? map['other']!).add(m);
    }
    return map;
  }
}