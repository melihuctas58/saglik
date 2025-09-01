class ExtractionConfig {
  double minLineScore;
  double minIngredientScore;
  int fuzzyDistance;
  double fuzzyRel;
  bool enableFuzzy;
  bool enableSubstring;
  int minGlobalOccurrences;
  ExtractionConfig({
    this.minLineScore = 0.35,
    this.minIngredientScore = 0.45,
    this.fuzzyDistance = 2,
    this.fuzzyRel = 0.25,
    this.enableFuzzy = true,
    this.enableSubstring = true,
    this.minGlobalOccurrences = 1,
  });

  ExtractionConfig copyWith({
    double? minLineScore,
    double? minIngredientScore,
    int? fuzzyDistance,
    double? fuzzyRel,
    bool? enableFuzzy,
    bool? enableSubstring,
    int? minGlobalOccurrences,
  }) => ExtractionConfig(
    minLineScore: minLineScore ?? this.minLineScore,
    minIngredientScore: minIngredientScore ?? this.minIngredientScore,
    fuzzyDistance: fuzzyDistance ?? this.fuzzyDistance,
    fuzzyRel: fuzzyRel ?? this.fuzzyRel,
    enableFuzzy: enableFuzzy ?? this.enableFuzzy,
    enableSubstring: enableSubstring ?? this.enableSubstring,
    minGlobalOccurrences: minGlobalOccurrences ?? this.minGlobalOccurrences,
  );
}

class ExtractionTuning {
  static final ExtractionConfig config = ExtractionConfig();
}