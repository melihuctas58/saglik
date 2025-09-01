import 'package:flutter/material.dart';
import '../viewmodels/ingredient_view_model.dart';
import '../models/ingredient.dart';
import '../widgets/ingredient_card.dart';

class IngredientListScreen extends StatefulWidget {
  const IngredientListScreen({super.key});

  @override
  State<IngredientListScreen> createState() => _IngredientListScreenState();
}

class _IngredientListScreenState extends State<IngredientListScreen> {
  late IngredientViewModel vm;
  final controller = TextEditingController();
  bool showFilters = false;
  String? selectedOrigin;
  String? riskFilter;

  @override
  void initState() {
    super.initState();
    vm = IngredientViewModel();
    vm.addListener(_vmListener);
    vm.init();
  }

  void _vmListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    vm.removeListener(_vmListener);
    vm.dispose();
    controller.dispose();
    super.dispose();
  }

  List<Ingredient> get visible {
    var list = vm.filtered;
    if (selectedOrigin != null) {
      list = list.where((i) => i.classification.originType == selectedOrigin).toList();
    }
    if (riskFilter != null) {
      list = list.where((i) => i.risk.riskLevel == riskFilter).toList();
    }
    return list;
  }

  void _search(String q) => vm.search(q);

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (vm.status) {
      case IngredientStatus.loading:
        body = const Center(child: CircularProgressIndicator());
        break;
      case IngredientStatus.error:
        body = Center(
          child: Text(
            'Hata:\n${vm.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        );
        break;
      case IngredientStatus.ready:
        final data = visible;
        if (data.isEmpty) {
            body = const Center(child: Text('Kayıt yok / filtre sonucu boş'));
        } else {
          body = ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: data.length,
            itemBuilder: (_, i) => IngredientCard(
              ingredient: data[i],
              onTap: () => Navigator.pushNamed(context, '/detail', arguments: data[i]),
            ),
          );
        }
        break;
      default:
        body = const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Malzeme Kütüphanesi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: Icon(showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () => setState(() => showFilters = !showFilters),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'compareFab',
        onPressed: () => Navigator.pushNamed(context, '/compare'),
        icon: const Icon(Icons.compare),
        label: const Text('Karşılaştır'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: controller,
              onChanged: (v) {
                setState(() {}); // clear icon yenile
                _search(v);
              },
              decoration: InputDecoration(
                hintText: 'İsim / kategori / synonym / E-numara ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          _search('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (showFilters) _Filters(
            selectedOrigin: selectedOrigin,
            riskFilter: riskFilter,
            onOriginChange: (o) => setState(() => selectedOrigin = o),
            onRiskChange: (r) => setState(() => riskFilter = r),
            onClear: () {
              setState(() {
                selectedOrigin = null;
                riskFilter = null;
              });
            },
          ),
          const Divider(height: 0),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final String? selectedOrigin;
  final String? riskFilter;
  final ValueChanged<String?> onOriginChange;
  final ValueChanged<String?> onRiskChange;
  final VoidCallback onClear;
  const _Filters({
    required this.selectedOrigin,
    required this.riskFilter,
    required this.onOriginChange,
    required this.onRiskChange,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final origins = [
      'bitkisel',
      'hayvansal',
      'mikrobiyal',
      'mineral',
      'sentetik',
      'karışık',
      'bilinmiyor'
    ];
    final risks = ['green', 'yellow', 'red'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: -4,
            children: origins.map((o) {
              final sel = o == selectedOrigin;
              return FilterChip(
                label: Text(o),
                selected: sel,
                onSelected: (_) => onOriginChange(sel ? null : o),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: -4,
            children: risks.map((r) {
              final sel = r == riskFilter;
              Color base;
              switch (r) {
                case 'green':
                  base = const Color(0xFF24A669);
                  break;
                case 'yellow':
                  base = const Color(0xFFE8A534);
                  break;
                case 'red':
                  base = const Color(0xFFD94343);
                  break;
                default:
                  base = Colors.grey;
              }
              return FilterChip(
                label: Text(r.toUpperCase()),
                selected: sel,
                selectedColor: base.withOpacity(.25),
                backgroundColor: base.withOpacity(.12),
                onSelected: (_) => onRiskChange(sel ? null : r),
              );
            }).toList(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh),
              label: const Text('Filtreleri Sıfırla'),
            ),
          )
        ],
      ),
    );
  }
}