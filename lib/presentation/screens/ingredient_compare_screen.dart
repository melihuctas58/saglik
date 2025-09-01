import 'package:flutter/material.dart';
import '../../domain/models/ingredient.dart';
import '../widgets/risk/risk_ring.dart';

class IngredientCompareScreen extends StatelessWidget {
  final List<Ingredient> items;
  const IngredientCompareScreen({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // Dinamik kolon sayısı => items.length (maks 4)
    final cols = items.length.clamp(1, 4);
    return Scaffold(
      appBar: AppBar(title: const Text('Karşılaştır')),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: cols * 260,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _headerRow(),
              const Divider(),
              _row('Kategori', (i)=> items[i].core.category),
              _row('Alt Kategori', (i)=> items[i].core.subcategory),
              _row('Origin', (i)=> items[i].classification.originType),
              _row('Risk Düzeyi', (i)=> items[i].risk.riskLevel.toUpperCase()),
              _rowWidget('Risk Skoru', (i)=> Center(
                child: RiskRing(score: items[i].risk.riskScore, level: items[i].risk.riskLevel, size: 54),
              )),
              _rowList('Risk Faktörleri', (i)=> items[i].risk.riskFactors),
              _rowList('Sağlık Flag', (i)=> items[i].health.healthFlags),
              _rowList('Roller', (i)=> items[i].usage.commonRoles),
              _rowList('Kullanım', (i)=> items[i].usage.whereUsed),
              _rowList('Mit Sayısı', (i)=> items[i].consumer.myths.map((m)=> m.myth).toList()),
              _row('Regülasyon (TR)', (i)=> items[i].regulatory.trStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      children: List.generate(items.length, (i) {
        final ing = items[i];
        return Expanded(
          child: Column(
            children: [
              Text(ing.core.primaryName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(ing.core.shortSummary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        );
      }),
    );
  }

  Widget _row(String label, String Function(int) getter) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (i) =>
          Expanded(child: _cell(label, getter(i), i==0))
        ),
      ),
    );
  }

  Widget _rowWidget(String label, Widget Function(int) builder) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(items.length, (i) =>
          Expanded(child: _cellWidget(label, builder(i), i==0))
        ),
      ),
    );
  }

  Widget _rowList(String label, List<String> Function(int) listGetter) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (i) {
          final list = listGetter(i);
          return Expanded(
            child: _cellWidget(
              label,
              Wrap(
                spacing: 4,
                runSpacing: -6,
                children: list.map((e) => Chip(
                  visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                  label: Text(e, style: const TextStyle(fontSize: 10)))).toList(),
              ),
              i==0
            ),
          );
        }),
      ),
    );
  }

  Widget _cell(String label, String value, bool showLabel) {
    return _cellWidget(label, Text(value, style: const TextStyle(fontSize: 12)), showLabel);
  }

  Widget _cellWidget(String label, Widget child, bool showLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        child
      ],
    );
  }
}