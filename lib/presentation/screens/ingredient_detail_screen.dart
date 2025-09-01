import 'package:flutter/material.dart';
import '../../domain/models/ingredient.dart';
import '../widgets/risk/risk_ring.dart';
import '../widgets/banners/allergen_banner.dart';
import '../widgets/sections/expandable_section.dart';

class IngredientDetailScreen extends StatelessWidget {
  final Ingredient ingredient;
  final bool technicalMode;
  const IngredientDetailScreen({
    super.key,
    required this.ingredient,
    this.technicalMode = false,
  });

  IconData get icon {
    switch (ingredient.core.iconHint) {
      case 'seed': return Icons.grass;
      case 'leaf': return Icons.eco;
      case 'oil': return Icons.oil_barrel_outlined;
      default: return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = _riskColor(ingredient.risk.riskLevel);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(ingredient.core.primaryName, maxLines: 1, overflow: TextOverflow.ellipsis),
              background: _buildHeader(context, col),
            ),
          )
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16,12,16,32),
          children: [
            AllergenBanner(
              allergenFlags: ingredient.allergen.allergenFlags,
              note: ingredient.allergen.note,
            ),
            _primarySections(),
            ExpandableSection(
              title: 'Kullanım & Fonksiyon',
              icon: Icons.workspaces,
              child: _usageSection(),
            ),
            ExpandableSection(
              title: 'Sağlık & Risk',
              icon: Icons.health_and_safety,
              child: _healthRiskSection(),
            ),
            ExpandableSection(
              title: 'Mit / Gerçek',
              icon: Icons.question_answer,
              child: _mythsSection(),
              initiallyExpanded: false,
            ),
            ExpandableSection(
              title: 'Regülasyon & Kaynaklar',
              icon: Icons.gavel,
              child: _regulatorySources(),
            ),
            if (technicalMode)
              ExpandableSection(
                title: 'Teknik Analiz',
                icon: Icons.science,
                child: _technicalHints(context),
              ),
            const SizedBox(height: 12),
            Text('Benzer / Alternatifler', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Burada “Benzer” (aynı kategori & subcategory) kısa kartları gösterirsin.
            // Placeholder:
            Text('Benzer malzemeler liste component (TODO)'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color col) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [col.withOpacity(.85), col.withOpacity(.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(.2),
            child: Icon(icon, size: 44, color: Colors.white),
          ),
            const SizedBox(width: 20),
          Expanded(
            child: Text(
              ingredient.core.userFriendlySummary.isNotEmpty
                  ? ingredient.core.shortSummary
                  : ingredient.core.primaryName,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          RiskRing(score: ingredient.risk.riskScore, level: ingredient.risk.riskLevel, size: 80),
        ],
      ),
    );
  }

  Widget _primarySections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Özet'),
        Text(ingredient.core.shortSummary),
        const SizedBox(height: 12),
        _sectionLabel('Detaylı Açıklama'),
        Text(ingredient.core.userFriendlySummary),
        const SizedBox(height: 12),
        _metaWrap(),
      ],
    );
  }

  Widget _metaWrap() {
    final chips = <Widget>[];
    void addChip(String? t) {
      if (t != null && t.trim().isNotEmpty) {
        chips.add(Chip(label: Text(t)));
      }
    }
    addChip(ingredient.core.category);
    addChip(ingredient.core.subcategory);
    addChip(ingredient.classification.originType);
    if (ingredient.identifiers.eNumber != null) addChip('E: ${ingredient.identifiers.eNumber}');
    if (ingredient.classification.isAdditive) addChip('Katkı');
    return Wrap(spacing: 8, runSpacing: -6, children: chips);
  }

  Widget _usageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniHeader('Kullanım Alanları'),
        Wrap(
          spacing: 8,
          children: ingredient.usage.whereUsed
              .map((e) => Chip(label: Text(e)))
              .toList(),
        ),
        const SizedBox(height: 8),
        _miniHeader('Roller'),
        Wrap(
          spacing: 8,
          children: ingredient.usage.commonRoles
              .map((e) => Chip(
                backgroundColor: Colors.blue.shade50,
                label: Text(e)))
              .toList(),
        ),
      ],
    );
  }

  Widget _healthRiskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (ingredient.health.healthFlags.isNotEmpty) ...[
          _miniHeader('Sağlık Etiketleri'),
          Wrap(
            spacing: 8,
            children: ingredient.health.healthFlags
                .map((f) => Chip(
                      backgroundColor: Colors.green.shade50,
                      label: Text(f),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        _miniHeader('Risk Faktörleri'),
        ...ingredient.risk.riskFactors.map((f) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(child: Text(f)),
          ],
        )),
        const SizedBox(height: 8),
        _miniHeader('Risk Açıklaması'),
        Text(ingredient.risk.riskExplanation),
        if (ingredient.health.safetyNotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _miniHeader('Güvenlik Notları'),
          Text(ingredient.health.safetyNotes),
        ],
      ],
    );
  }

  Widget _mythsSection() {
    if (ingredient.consumer.myths.isEmpty) {
      return const Text('Mit kaydı yok.');
    }
    return Column(
      children: ingredient.consumer.myths.map((m) => Card(
        color: Colors.purple.shade50,
        child: ListTile(
          title: Text('Mit: ${m.myth}'),
          subtitle: Text('Gerçek: ${m.fact}', style: const TextStyle(color: Colors.purple)),
        ),
      )).toList(),
    );
  }

  Widget _regulatorySources() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miniHeader('Regülasyon'),
        Text('TR: ${ingredient.regulatory.trStatus}'),
        Text('EU: ${ingredient.regulatory.euStatus}'),
        Text('US: ${ingredient.regulatory.usStatus}'),
        if (ingredient.regulatory.adiMgPerKgBw != null)
          Text('ADI: ${ingredient.regulatory.adiMgPerKgBw} mg/kg'),
        const SizedBox(height: 12),
        _miniHeader('Kaynaklar'),
        if (ingredient.sources.isEmpty) const Text('Kaynak yok')
        else ...ingredient.sources.map((s) => ListTile(
          dense: true,
          leading: const Icon(Icons.link, size: 18, color: Colors.blue),
          title: Text(s.name),
          subtitle: s.note != null ? Text(s.note!) : null,
          onTap: s.url != null ? () {
            // launchUrl(...)
          } : null,
        ))
      ],
    );
  }

  Widget _technicalHints(BuildContext context) {
    // Burada ileride: GC, PV, TOTOX field placeholder
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Teknik göstergeler (örnek placeholder):', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        _metricRow('Oksidasyon İzleme', 'Peroksit / Anisidin / TOTOX'),
        _metricRow('Adulterasyon Kontrol', 'Yağ asidi profili • Sterol • TAG fingerprint'),
        _metricRow('Stabilite', 'Işık / O2 bariyer ambalaj'),
      ],
    );
  }

  Widget _metricRow(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 140, child: Text(k, style: const TextStyle(fontWeight: FontWeight.w500))),
        Expanded(child: Text(v)),
      ],
    ),
  );

  Color _riskColor(String level) {
    switch(level) {
      case 'green': return const Color(0xFF24A669);
      case 'yellow': return const Color(0xFFE8A534);
      case 'red': return const Color(0xFFD94343);
      default: return Colors.grey;
    }
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
  );

  Widget _miniHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(t,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: .2),
    ),
  );
}