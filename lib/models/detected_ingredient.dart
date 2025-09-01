import 'dart:ui';

class DetectedIngredient {
  final String canonical;
  final String risk;
  final double score;
  final List<Rect> boxes;
  final DateTime firstSeen;
  final DateTime lastSeen;

  DetectedIngredient({
    required this.canonical,
    required this.risk,
    required this.score,
    required this.boxes,
    required this.firstSeen,
    required this.lastSeen,
  });

  DetectedIngredient update({
    double? score,
    List<Rect>? boxes,
  }) => DetectedIngredient(
    canonical: canonical,
    risk: risk,
    score: score ?? this.score,
    boxes: boxes ?? this.boxes,
    firstSeen: firstSeen,
    lastSeen: DateTime.now(),
  );

  Duration get age => DateTime.now().difference(firstSeen);
}