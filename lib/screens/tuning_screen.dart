import 'package:flutter/material.dart';
import '../services/ingredient_extraction_service.dart';
import '../services/ingredient_extraction_config.dart';

class TuningScreen extends StatefulWidget {
  const TuningScreen({super.key});
  @override
  State<TuningScreen> createState() => _TuningScreenState();
}

class _TuningScreenState extends State<TuningScreen> {
  final ctrl = TextEditingController(text: 'İÇİNDEKİLER: Ayçiçek yağı, Palm yağı (fraksiyone), Sitrik asit (E330), Lesitin (E322), Askorbik asit (E300)');
  ExtractionResult? result;

  ExtractionConfig get cfg => ExtractionTuning.config;

  void _run() {
    final service = IngredientExtractionService();
    setState(() {
      result = service.extract(ctrl.text);
    });
  }

  Widget _slider(String label, double value, double min, double max, void Function(double) onChanged, {int divisions=100}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(2)}'),
        Slider(value: value, min: min, max: max, divisions: divisions, onChanged: (v){ setState(()=> onChanged(v)); }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Scaffold(
      appBar: AppBar(title: const Text('Extraction Tuning')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Ham Metin', style: Theme.of(context).textTheme.titleMedium),
          TextField(
            controller: ctrl,
            maxLines: 6,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          _slider('minLineScore', cfg.minLineScore, 0.1, 1.0, (v)=> cfg.minLineScore = v),
          _slider('minIngredientScore', cfg.minIngredientScore, 0.1, 1.0, (v)=> cfg.minIngredientScore = v),
          _slider('fuzzyRel', cfg.fuzzyRel, 0.05, 0.5, (v)=> cfg.fuzzyRel = v),
          Row(
            children: [
              Expanded(child: Text('fuzzyDistance: ${cfg.fuzzyDistance}')),
              Slider(value: cfg.fuzzyDistance.toDouble(), min: 0, max: 3, divisions: 3, onChanged: (v){ setState(()=> cfg.fuzzyDistance = v.toInt()); }),
            ],
          ),
          SwitchListTile(
            title: const Text('enableFuzzy'),
            value: cfg.enableFuzzy,
            onChanged: (v)=> setState(()=> cfg.enableFuzzy = v),
          ),
            SwitchListTile(
            title: const Text('enableSubstring'),
            value: cfg.enableSubstring,
            onChanged: (v)=> setState(()=> cfg.enableSubstring = v),
          ),
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('ÇALIŞTIR'),
                onPressed: _run,
              )),
            ],
          ),
          const SizedBox(height: 12),
          if (r != null) ...[
            Text('Bulunan Malzemeler (${r.ingredients.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            ...r.ingredients.map((e)=> ListTile(
              title: Text('${e.canonical}  (${e.score})'),
              subtitle: Text(e.lines.join(' | '), maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Text(e.matchedVariants.length.toString()),
            )),
            const Divider(),
            ExpansionTile(
              title: Text('Ham Items (${r.rawItems.length})'),
              children: r.rawItems.map((e)=> ListTile(title: Text(e))).toList(),
            ),
            ExpansionTile(
              title: const Text('Debug Lines'),
              children: r.debugLines.map((d)=> ListTile(
                title: Text(d.raw),
                subtitle: Text(d.partialScores.entries.map((e)=> '${e.key}:${e.value.toStringAsFixed(2)}').join('  ')),
              )).toList(),
            )
          ]
        ],
      ),
    );
  }
}