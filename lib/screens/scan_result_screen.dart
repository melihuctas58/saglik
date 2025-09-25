import 'dart:io';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../utils/risk_colors.dart';
import '../utils/risk_labels.dart';
import 'ingredient_detail_screen.dart';

class ScanResultScreen extends StatelessWidget {
  final List<Ingredient> ingredients;
  final String rawText;
  final String? imagePath;
  const ScanResultScreen({
    super.key,
    required this.ingredients,
    required this.rawText,
    this.imagePath,
  });

  // Yeni eşikler
  String _levelFromScore(int score) {
    if (score >= 400) return 'red';
    if (score >= 250) return 'yellow';
    return 'green';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final groups = _groupByRisk(ingredients);
    final total = ingredients.length;
    final green = groups['green']!.length;
    final yellow = groups['yellow']!.length;
    final red = groups['red']!.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Tarama Sonuçları')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              border: Border.all(color: Colors.amber.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.black87),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu sonuçlar otomatik çıkarımdır; yapay zeka yanılabilir. Lütfen ürün etiketini ve üretici beyanını kontrol ederek doğrulayın.',
                    style: TextStyle(color: Colors.brown.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _SummaryCard(total: total, green: green, yellow: yellow, red: red),
          const SizedBox(height: 12),

          if ((imagePath ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
            ),
          if ((imagePath ?? '').isNotEmpty) const SizedBox(height: 12),

          if (red > 0) _Section(title: 'Yüksek risk', color: riskColorOf('red'), items: groups['red']!),
          if (yellow > 0) _Section(title: 'Orta risk', color: riskColorOf('yellow'), items: groups['yellow']!),
          if (green > 0) _Section(title: 'Düşük risk', color: riskColorOf('green'), items: groups['green']!),
          if (total == 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Hiç malzeme bulunamadı.'),
            ),

          const SizedBox(height: 16),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              initiallyExpanded: false,
              title: const Text('Ham Metin', style: TextStyle(fontWeight: FontWeight.w800)),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rawText,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Ingredient>> _groupByRisk(List<Ingredient> list) {
    final m = {
      'red': <Ingredient>[],
      'yellow': <Ingredient>[],
      'green': <Ingredient>[],
      'other': <Ingredient>[],
    };
    for (final i in list) {
      final score = i.risk.riskScore;
      final level = _levelFromScore(score);
      if (level == 'red') m['red']!.add(i);
      else if (level == 'yellow') m['yellow']!.add(i);
      else if (level == 'green') m['green']!.add(i);
      else m['other']!.add(i);
    }
    return m;
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int green;
  final int yellow;
  final int red;
  const _SummaryCard({required this.total, required this.green, required this.yellow, required this.red});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget chip(String label, Color color, int count) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        border: Border.all(color: color.withOpacity(.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $count', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Özet', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Toplam: $total', style: const TextStyle(fontWeight: FontWeight.w700))),
              Wrap(
                spacing: 8,
                children: [
                  chip(riskLabelOf('red'), riskColorOf('red'), red),
                  chip(riskLabelOf('yellow'), riskColorOf('yellow'), yellow),
                  chip(riskLabelOf('green'), riskColorOf('green'), green),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final List<Ingredient> items;
  const _Section({required this.title, required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          ),
          ...items.map((ing) => ListTile(
                dense: true,
                title: Text(ing.core.primaryName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(ing.core.shortSummary, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    border: Border.all(color: color.withOpacity(0.35)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => IngredientDetailScreen(ingredient: ing),
                )),
              )),
        ],
      ),
    );
  }
}