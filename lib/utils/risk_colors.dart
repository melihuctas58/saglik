import 'package:flutter/material.dart';

Color riskColorOf(String? level) {
  switch ((level ?? '').toLowerCase()) {
    case 'green':
      return Colors.green.shade700;
    case 'yellow':
    case 'amber':
      return Colors.amber.shade700;
    case 'red':
      return Colors.red.shade700;
    default:
      return Colors.blueGrey.shade700;
  }
}

// Yeni skala: 0..1000
// 0..249 -> yeşil, 250..399 -> sarı, 400+ -> kırmızı
Color riskColorFromScore(int? score) {
  if (score == null) return Colors.blueGrey.shade700;
  if (score >= 400) return Colors.red.shade700;
  if (score >= 250) return Colors.amber.shade700;
  return Colors.green.shade700;
}