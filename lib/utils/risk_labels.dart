String riskLabelOf(String? level) {
  switch ((level ?? '').toLowerCase()) {
    case 'green':
    case 'low':
    case 'düşük':
      return 'Düşük risk';
    case 'yellow':
    case 'amber':
    case 'medium':
    case 'orta':
      return 'Orta risk';
    case 'red':
    case 'high':
    case 'yüksek':
      return 'Yüksek risk';
    default:
      return 'Bilinmiyor';
  }
}

// Yeni skala: 0..1000
// 0..249 -> Düşük, 250..399 -> Orta, 400+ -> Yüksek
String riskLabelFromScore(int? score) {
  if (score == null) return 'Bilinmiyor';
  if (score >= 400) return 'Yüksek risk';
  if (score >= 250) return 'Orta risk';
  return 'Düşük risk';
}