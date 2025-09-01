import 'package:flutter/material.dart';
import '../viewmodels/scan_result_view_model.dart';
import '../services/ingredient_advanced_match_service.dart';
import '../models/scan_result_args.dart';
import '../utils/text_format.dart';

class ScanResultScreen extends StatefulWidget {
  final ScanResultArgs args;
  const ScanResultScreen({super.key, required this.args});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen>
    with SingleTickerProviderStateMixin {
  late ScanResultViewModel vm;
  late TabController tabController;
  final tabs = const [
    Tab(text: 'Hepsi'),
    Tab(text: 'Kırmızı'),
    Tab(text: 'Sarı'),
    Tab(text: 'Yeşil'),
  ];

  @override
  void initState() {
    super.initState();
    vm = ScanResultViewModel(service: widget.args.advancedService);
    vm.addListener(_listener);
    vm.compute(tokens: widget.args.tokens, phrases: widget.args.phrases);
    tabController = TabController(length: tabs.length, vsync: this);
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    vm.removeListener(_listener);
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = vm.groupedByRisk();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarama Sonuçları'),
        bottom: TabBar(controller: tabController, tabs: tabs),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _buildList(vm.matches),
          _buildList(grouped['red'] ?? []),
          _buildList(grouped['yellow'] ?? []),
          _buildList(grouped['green'] ?? []),
        ],
      ),
      bottomNavigationBar: _unknownSection(),
    );
  }

  Widget _unknownSection() {
    if (vm.unknownTokens.isEmpty) return const SizedBox(height: 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Eşleşmeyen (${vm.unknownTokens.length})',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: -6,
            children: vm.unknownTokens
                .map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade300,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<AdvancedIngredientMatch> list) {
    if (list.isEmpty) {
      return Center(
        child:
            Text('Kayıt yok', style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: list.length,
      itemBuilder: (_, i) => _matchTile(list[i]),
    );
  }

  Widget _matchTile(AdvancedIngredientMatch m) {
    final ing = m.ingredient;
    final color = _riskColor(ing.risk.riskLevel);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.18),
          child: Text(
            (ing.risk.riskScore ~/ 100).toString(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(prettifyLabel(ing.core.primaryName)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skor:${m.score.toStringAsFixed(2)}  Tam:${m.intersectCount}  Fz:${m.fuzzyCount}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            if (m.phraseHits > 0)
              Text('Phrase x${m.phraseHits}',
                  style:
                      TextStyle(fontSize: 10, color: Colors.purple.shade600)),
            const SizedBox(height: 2),
            Text(
              m.matchedTokens.join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              ing.risk.riskExplanation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            ing.risk.riskLevel.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        onTap: () =>
            Navigator.pushNamed(context, '/detail', arguments: ing),
      ),
    );
  }

  Color _riskColor(String l) {
    switch (l) {
      case 'red':
        return const Color(0xFFD94343);
      case 'yellow':
        return const Color(0xFFE8A534);
      case 'green':
        return const Color(0xFF24A669);
      default:
        return Colors.grey;
    }
  }
}