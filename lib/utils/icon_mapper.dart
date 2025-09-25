import 'package:flutter/material.dart';

IconData iconForHint(String? hint) {
  final h = (hint ?? '').toLowerCase();
  if (h.contains('protein')) return Icons.fitness_center;
  if (h.contains('asit') || h.contains('acid')) return Icons.science;
  if (h.contains('yağ') || h.contains('oil') || h.contains('fat')) return Icons.oil_barrel;
  if (h.contains('renk') || h.contains('color')) return Icons.palette_outlined;
  if (h.contains('lif') || h.contains('fiber')) return Icons.grass_rounded;
  return Icons.category_outlined;
}