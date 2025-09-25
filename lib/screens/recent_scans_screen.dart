// Taramalar: "Ham metin" zaten gizlenmişti, şimdi görüntüler de gizlendi.
// Üstte "Son tarananlar" başlığı var.
import 'package:flutter/material.dart';
import '../services/scan_history_service.dart';
import '../models/ingredient.dart';

class RecentScansScreen extends StatelessWidget {
  final void Function(Ingredient ing) onOpenIngredient;
  const RecentScansScreen({super.key, required this.onOpenIngredient});

  @override
  Widget build(BuildContext context) {
    final history = ScanHistoryService.instance.records;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Taramalar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          Text(
            'Son tarananlar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Henüz tarama yok.'),
            ),
          for (final rec in history) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtDate(rec.timestamp),
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  // Görüntüler görünmesin: imagePath KULLANMIYORUZ
                  // Bulunan malzemeler (chip’ler)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: rec.ingredients
                        .map((ing) => ActionChip(
                              label: Text(ing.core.primaryName),
                              onPressed: () => onOpenIngredient(ing),
                            ))
                        .toList(),
                  ),
                  // Ham metin de YOK
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }
}