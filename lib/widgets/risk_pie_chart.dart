import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/scan_history_service.dart';
import '../utils/risk_colors.dart';

class RiskPieChart extends StatelessWidget {
  final List<ScanRecord> records;
  final int lookback; // kaç kaydı sayalım
  const RiskPieChart({super.key, required this.records, this.lookback = 30});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = _aggregate();
    final total = data['red']! + data['yellow']! + data['green']!;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Son taramalar için risk verisi yok.'),
      );
    }

    final sections = <PieChartSectionData>[
      if (data['red']! > 0)
        PieChartSectionData(
          color: riskColorOf('red'),
          value: data['red']!.toDouble(),
          title: '',
          radius: 48,
        ),
      if (data['yellow']! > 0)
        PieChartSectionData(
          color: riskColorOf('yellow'),
          value: data['yellow']!.toDouble(),
          title: '',
          radius: 48,
        ),
      if (data['green']! > 0)
        PieChartSectionData(
          color: riskColorOf('green'),
          value: data['green']!.toDouble(),
          title: '',
          radius: 48,
        ),
    ];

    Widget legend(String label, Color c, int v) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('$label: $v', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
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
          const Text('Son Taramalar – Risk Dağılımı', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    startDegreeOffset: -90,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Toplam', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    Text('$total', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              legend('Yüksek', riskColorOf('red'), data['red']!),
              legend('Orta', riskColorOf('yellow'), data['yellow']!),
              legend('Düşük', riskColorOf('green'), data['green']!),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, int> _aggregate() {
    final counts = {'red': 0, 'yellow': 0, 'green': 0};
    for (final rec in records.take(lookback)) {
      for (final ing in rec.ingredients) {
        final level = (ing.risk.riskLevel.isNotEmpty ? ing.risk.riskLevel : ing.risk.labelColor).toLowerCase();
        if (level == 'red') counts['red'] = counts['red']! + 1;
        else if (level == 'yellow' || level == 'amber') counts['yellow'] = counts['yellow']! + 1;
        else if (level == 'green') counts['green'] = counts['green']! + 1;
      }
    }
    return counts;
    }
}