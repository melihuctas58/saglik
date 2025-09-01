import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../widgets/risk_bar.dart';
import '../widgets/diet_badges.dart';

class IngredientDetailScreen extends StatelessWidget {
  final Ingredient ingredient;
  const IngredientDetailScreen({required this.ingredient, super.key});

  IconData get icon {
    switch (ingredient.core.iconHint) {
      case 'seed':
        return Icons.grass;
      case 'leaf':
        return Icons.eco;
      case 'oil':
        return Icons.oil_barrel_outlined;
      default:
        return Icons.fastfood;
    }
  }

  Color get riskColor {
    switch (ingredient.risk.labelColor) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: .2,
        )),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(ingredient.core.primaryName),
        backgroundColor: riskColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: riskColor.withOpacity(.18),
                child: Icon(icon, color: riskColor, size: 38),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  ingredient.core.primaryName,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RiskBar(score: ingredient.risk.riskScore, level: ingredient.risk.riskLevel),
          const SizedBox(height: 14),
          DietBadges(dietary: ingredient.dietary),
          const SizedBox(height: 20),

          _sectionTitle('Özet'),
          Text(ingredient.core.shortSummary),
          _sectionTitle('Detaylı Açıklama'),
          Text(ingredient.core.userFriendlySummary),

          if (ingredient.identifiers.eNumber != null) ...[
            _sectionTitle('E-Numara'),
            Text(ingredient.identifiers.eNumber!),
          ],
          _sectionTitle('Kategori'),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(ingredient.core.category)),
              if (ingredient.core.subcategory.isNotEmpty)
                Chip(label: Text(ingredient.core.subcategory)),
              if (ingredient.classification.isAdditive)
                const Chip(label: Text('Katkı'))
            ],
          ),

          _sectionTitle('Kullanım Alanları'),
          Wrap(
            spacing: 8,
            children: ingredient.usage.whereUsed
                .map((e) => Chip(label: Text(e)))
                .toList(),
          ),
          _sectionTitle('Yaygın İşlevler'),
          Wrap(
            spacing: 8,
            children: ingredient.usage.commonRoles
                .map((e) => Chip(
                  backgroundColor: Colors.blue.shade50,
                  label: Text(e),
                ))
                .toList(),
          ),

          _sectionTitle('Risk Faktörleri'),
          ...ingredient.risk.riskFactors.map((f) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• '),
              Expanded(child: Text(f)),
            ],
          )),
          _sectionTitle('Risk Açıklaması'),
          Text(ingredient.risk.riskExplanation),

          if (ingredient.health.healthFlags.isNotEmpty) ...[
            _sectionTitle('Sağlık Etiketleri'),
            Wrap(
              spacing: 8,
              children: ingredient.health.healthFlags
                  .map((f) => Chip(
                backgroundColor: Colors.green.shade50,
                label: Text(f),
              ))
                  .toList(),
            ),
          ],
          if (ingredient.health.safetyNotes.isNotEmpty) ...[
            _sectionTitle('Güvenlik Notları'),
            Text(ingredient.health.safetyNotes),
          ],

          if (ingredient.consumer.myths.isNotEmpty) ...[
            _sectionTitle('Mit / Gerçek'),
            ...ingredient.consumer.myths.map((m) => Card(
              color: Colors.purple.shade50,
              child: ListTile(
                title: Text('Mit: ${m.myth}'),
                subtitle: Text('Gerçek: ${m.fact}',
                    style: const TextStyle(color: Colors.purple)),
              ),
            ))
          ],

          _sectionTitle('Regülasyon'),
          Text('TR: ${ingredient.regulatory.trStatus}'),
            Text('EU: ${ingredient.regulatory.euStatus}'),
          Text('US: ${ingredient.regulatory.usStatus}'),
          if (ingredient.regulatory.adiMgPerKgBw != null)
            Text('ADI: ${ingredient.regulatory.adiMgPerKgBw} mg/kg'),

          _sectionTitle('Kaynaklar'),
          ...ingredient.sources.map((s) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.link, size: 20, color: Colors.blue),
            title: Text(s.name),
            subtitle: s.note != null ? Text(s.note!) : null,
            onTap: s.url != null ? () {
              // url_launcher ile açabilirsin
            } : null,
          )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}