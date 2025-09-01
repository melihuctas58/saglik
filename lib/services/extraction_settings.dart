import 'package:flutter/foundation.dart';

class ExtractionSettings extends ChangeNotifier {
  static final ExtractionSettings instance = ExtractionSettings._();
  ExtractionSettings._();

  double minLineScore = 0.35;
  double minIngredientScore = 0.45;
  int fuzzyDistance = 2;
  double fuzzyRel = 0.25;
  bool enableFuzzy = true;
  bool enableSubstring = true;
  int minGlobalOccurrences = 1;
  bool showBoxes = true;
  bool pulseAnimation = true;
  int ocrIntervalMs = 550;

  void update({
    double? minLineScore,
    double? minIngredientScore,
    int? fuzzyDistance,
    double? fuzzyRel,
    bool? enableFuzzy,
    bool? enableSubstring,
    int? minGlobalOccurrences,
    bool? showBoxes,
    bool? pulseAnimation,
    int? ocrIntervalMs,
  }) {
    if (minLineScore != null) this.minLineScore = minLineScore;
    if (minIngredientScore != null) this.minIngredientScore = minIngredientScore;
    if (fuzzyDistance != null) this.fuzzyDistance = fuzzyDistance;
    if (fuzzyRel != null) this.fuzzyRel = fuzzyRel;
    if (enableFuzzy != null) this.enableFuzzy = enableFuzzy;
    if (enableSubstring != null) this.enableSubstring = enableSubstring;
    if (minGlobalOccurrences != null) {
      this.minGlobalOccurrences = minGlobalOccurrences;
    }
    if (showBoxes != null) this.showBoxes = showBoxes;
    if (pulseAnimation != null) this.pulseAnimation = pulseAnimation;
    if (ocrIntervalMs != null) this.ocrIntervalMs = ocrIntervalMs;
    notifyListeners();
  }
}