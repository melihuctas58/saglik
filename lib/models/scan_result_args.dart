import '../services/ingredient_advanced_match_service.dart';

class ScanResultArgs {
  final List<String> tokens;
  final List<String> phrases;
  final AdvancedIngredientMatchService advancedService;

  ScanResultArgs({
    required this.tokens,
    required this.phrases,
    required this.advancedService,
  });
}