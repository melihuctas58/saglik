import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../utils/text_format.dart';
import '../utils/risk_colors.dart';
import '../utils/risk_labels.dart';
import 'ingredient_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final List<Ingredient> allIngredients;
  final Set<String>? initialFilters;
  final String? initialQuery;

  const SearchScreen({
    super.key,
    required this.allIngredients,
    this.initialFilters,
    this.initialQuery,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String q = '';
  final Set<String> filters = {};
  String? origin;
  bool onlyAdditives = false;
  RangeValues riskRange = const RangeValues(0, 4000);
  String sort = 'relevance';

  @override
  void initState() {
    super.initState();
    q = widget.initialQuery ?? '';
    if (widget.initialFilters != null) {
      filters.addAll(widget.initialFilters!);
      if (filters.contains('additive')) onlyAdditives = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _applyFilters(widget.allIngredients.toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arama'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            initialValue: sort,
            onSelected: (v) => setState(() => sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'relevance', child: Text('Alaka')),
              PopupMenuItem(value: 'risk_desc', child: Text('Risk Skoru: Yüksek -> Düşük')),
              PopupMenuItem(value: 'risk_asc', child: Text('Risk Skoru: Düşük -> Yüksek')),
              PopupMenuItem(value: 'alpha', child: Text('A-Z')),
            ],
          ),
          IconButton(
            tooltip: 'Gelişmiş Filtreler',
            icon: const Icon(Icons.tune),
            onPressed: _openAdvancedFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: TextEditingController(text: q)
                ..selection = TextSelection.collapsed(offset: q.length),
              decoration: InputDecoration(
                hintText: 'Malzeme ara (örn. E355, sitrik asit...)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (v) => setState(() => q = v),
              onChanged: (v) => setState(() => q = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _FilterChip(label: 'Vegan', value: 'vegan', active: filters.contains('vegan'), onTap: _toggle),
                _FilterChip(label: 'Vejetaryen', value: 'vegetarian', active: filters.contains('vegetarian'), onTap: _toggle),
                _FilterChip(label: 'Glutensiz', value: 'gluten_free', active: filters.contains('gluten_free'), onTap: _toggle),
                _FilterChip(label: 'Laktozsuz', value: 'lactose_free', active: filters.contains('lactose_free'), onTap: _toggle),
                _FilterChip(label: 'Helal', value: 'helal', active: filters.contains('helal'), onTap: _toggle),
                _FilterChip(label: 'Kosher', value: 'kosher', active: filters.contains('kosher'), onTap: _toggle),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final ing = list[i];
                final score = ing.risk.riskScore;
                final color = riskColorFromScore(score);
                final label = riskLabelFromScore(score);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  title: Text(ing.core.primaryName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(ing.core.shortSummary, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      border: Border.all(color: color.withOpacity(0.35)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => IngredientDetailScreen(ingredient: ing),
                  )),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(String v) {
    setState(() {
      if (filters.contains(v)) {
        filters.remove(v);
      } else {
        filters.add(v);
      }
    });
  }

  void _openAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              void setBoth(VoidCallback fn) {
                setSheet(fn);
                setState(fn);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gelişmiş Filtreler', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Switch(
                        value: onlyAdditives,
                        onChanged: (v) => setBoth(() => onlyAdditives = v),
                      ),
                      const Text('Sadece katkılar'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Köken', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Hepsi'),
                        selected: origin == null,
                        onSelected: (v) => setBoth(() => origin = null),
                      ),
                      ChoiceChip(
                        label: const Text('Bitkisel'),
                        selected: origin == 'bitkisel',
                        onSelected: (v) => setBoth(() => origin = 'bitkisel'),
                      ),
                      ChoiceChip(
                        label: const Text('Hayvansal'),
                        selected: origin == 'hayvansal',
                        onSelected: (v) => setBoth(() => origin = 'hayvansal'),
                      ),
                      ChoiceChip(
                        label: const Text('Sentetik'),
                        selected: origin == 'sentetik',
                        onSelected: (v) => setBoth(() => origin = 'sentetik'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Risk Skoru (0–4000)', style: TextStyle(fontWeight: FontWeight.w700)),
                  RangeSlider(
                    values: riskRange,
                    min: 0,
                    max: 4000,
                    divisions: 40,
                    labels: RangeLabels(riskRange.start.round().toString(), riskRange.end.round().toString()),
                    onChanged: (v) => setBoth(() => riskRange = v),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check),
                      label: const Text('Uygula'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<Ingredient> _applyFilters(List<Ingredient> base) {
    final query = normalizeForSearch(q);
    var filtered = base.where((i) {
      if (query.isNotEmpty) {
        final text = normalizeForSearch('${i.core.primaryName} ${i.core.shortSummary} ${i.core.category} ${i.core.subcategory}');
        if (!text.contains(query)) return false;
      }
      if (filters.contains('vegan') && !i.dietary.vegan) return false;
      if (filters.contains('vegetarian') && !i.dietary.vegetarian) return false;
      if (filters.contains('gluten_free') && !i.dietary.glutenFree) return false;
      if (filters.contains('lactose_free') && !i.dietary.lactoseFree) return false;
      if (filters.contains('kosher') && !i.dietary.kosher) return false;
      if (filters.contains('helal')) {
        final h = i.dietary.halal.toLowerCase();
        if (!(h == 'helal' || h == 'halal' || h == 'yes' || h == 'true' || h == 'evet')) return false;
      }
      if (onlyAdditives && !i.classification.isAdditive) return false;
      if (origin != null && origin!.isNotEmpty) {
        if (i.classification.originType.toLowerCase() != origin) return false;
      }
      if (i.risk.riskScore < riskRange.start || i.risk.riskScore > riskRange.end) return false;
      return true;
    }).toList();

    switch (sort) {
      case 'risk_desc':
        filtered.sort((a, b) => b.risk.riskScore.compareTo(a.risk.riskScore));
        break;
      case 'risk_asc':
        filtered.sort((a, b) => a.risk.riskScore.compareTo(b.risk.riskScore));
        break;
      case 'alpha':
        filtered.sort((a, b) => a.core.primaryName.toLowerCase().compareTo(b.core.primaryName.toLowerCase()));
        break;
      case 'relevance':
      default:
        if (query.isNotEmpty) {
          filtered.sort((a, b) {
            final an = a.core.primaryName.toLowerCase().contains(query);
            final bn = b.core.primaryName.toLowerCase().contains(query);
            if (an && !bn) return -1;
            if (!an && bn) return 1;
            return 0;
          });
        }
    }
    return filtered;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final void Function(String) onTap;
  const _FilterChip({required this.label, required this.value, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? c.primary.withOpacity(0.12) : c.surfaceVariant,
            border: Border.all(color: active ? c.primary : c.outlineVariant),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              if (active) Icon(Icons.check, size: 16, color: c.primary),
              if (active) const SizedBox(width: 6),
              Text(label, style: TextStyle(color: active ? c.primary : null, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}