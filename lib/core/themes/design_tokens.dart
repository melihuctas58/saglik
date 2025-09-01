import 'package:flutter/material.dart';

class AppColors {
  static const riskGreen = Color(0xFF24A669);
  static const riskYellow = Color(0xFFE8A534);
  static const riskRed = Color(0xFFD94343);
  static const surfaceAlt = Color(0xFFF5F8FC);
  static const originBitkisel = Color(0xFF3B7D3B);
  static const originHayvansal = Color(0xFF9B3D2E);
  static const originMikrobiyal = Color(0xFF1E7A9C);
  static const originMineral = Color(0xFF6D6F7A);
  static const originSentetik = Color(0xFF5A3DB8);
  static const originKarışık = Color(0xFF575757);
  static const originBilinmiyor = Color(0xFF9E9E9E);
}

Color riskColor(String level) {
  switch (level) {
    case 'green': return AppColors.riskGreen;
    case 'yellow': return AppColors.riskYellow;
    case 'red': return AppColors.riskRed;
    default: return Colors.grey;
  }
}