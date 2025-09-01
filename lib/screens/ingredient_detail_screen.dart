import 'package:flutter/material.dart';
import '../services/popularity_service.dart';
import '../widgets/expandable_card.dart';

class IngredientDetailScreen extends StatelessWidget {
  final dynamic ingredient;
  const IngredientDetailScreen({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final name = (ingredient.core?.primaryName ?? '').toString();
    final pop = PopularityService.instance.count(
      ingredient,
      keyFn: (x) => (x.core?.primaryName ?? '').toString().toLowerCase(),
    );
    final risk = (ingredient.risk?.riskLevel ?? 'Bilinmiyor').toString();

    return Scaffold(
      appBar: AppBar(title: Text(name.isEmpty ? 'Detay' : name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.red.shade100,
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
              )
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge('Risk: $risk', _riskColor(risk)),
              _badge('Popülerlik: $pop', Colors.orange.shade600),
            ],
          ),
          const SizedBox(height: 24),
          ExpandableCard(
            title: 'Alternatif İsimler',
            initiallyExpanded: true,
            child: _altNames(),
          ),
            const SizedBox(height: 12),
          ExpandableCard(
            title: 'Risk Faktörleri',
            child: _riskFactors(),
          ),
          const SizedBox(height: 12),
          ExpandableCard(
            title: 'Kullanım / Nerede Bulunur',
            child: _usage(),
          ),
        ],
      ),
    );
  }

  Widget _altNames() {
    final out = <String>[];
    final map = ingredient.core?.names;
    if (map is Map) {
      map.forEach((_, v) {
        if (v is String && v.isNotEmpty) out.add(v);
        else if (v is List) {
          for (final s in v) {
            final ss = s.toString();
            if (ss.isNotEmpty) out.add(ss);
          }
        }
      });
    }
    if (out.isEmpty) return const Text('Veri yok.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: out
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• $e'),
              ))
          .toList(),
    );
  }

  Widget _riskFactors() {
    final rf = ingredient.risk?.riskFactors;
    if (rf is List && rf.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rf
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $e'),
                ))
            .toList(),
      );
    }
    return const Text('Veri yok.');
  }

  Widget _usage() {
    final b = StringBuffer();
    final where = ingredient.usage?.whereUsed;
    final roles = ingredient.usage?.commonRoles;
    if (where is List && where.isNotEmpty) {
      b.writeln('Nerede Kullanılır:');
      for (final w in where) {
        b.writeln(' • $w');
      }
    }
    if (roles is List && roles.isNotEmpty) {
      if (b.isNotEmpty) b.writeln();
      b.writeln('Roller:');
      for (final r in roles) {
        b.writeln(' • $r');
      }
    }
    if (b.isEmpty) return const Text('Veri yok.');
    return Text(b.toString().trim());
  }

  Widget _badge(String text, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: c.withOpacity(.14), borderRadius: BorderRadius.circular(24)),
      child: Text(text,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
      case 'yüksek':
        return Colors.red.shade600;
      case 'medium':
      case 'orta':
        return Colors.orange.shade600;
      case 'low':
      case 'düşük':
        return Colors.green.shade600;
    }
    return Colors.blueGrey.shade600;
  }
}