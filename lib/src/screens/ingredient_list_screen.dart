import 'package:flutter/material.dart';
import '../viewmodels/ingredient_view_model.dart';
import '../models/ingredient.dart';
import '../widgets/ingredient_item_card.dart';
import 'ingredient_detail_screen.dart';

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
    vm.addListener(_onVmChanged);
    vm.init();
  }

  void _onVmChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    vm.removeListener(_onVmChanged);
    vm.dispose();
    controller.dispose();
    super.dispose();
  }

  List<Ingredient> get _visible {
    var list = vm.filtered;
    if (selectedOrigin != null) {
      list = list.where((i) => i.classification.originType == selectedOrigin).toList();
    }
    if (riskFilter != null) {
      list = list.where((i) => i.risk.riskLevel == riskFilter).toList();
    }
    return list;
  }

  void _onSearch(String q) => vm.search(q);

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (vm.status) {
      case IngredientStateStatus.loading:
        body = const Center(child: CircularProgressIndicator());
        break;
      case IngredientStateStatus.error:
        body = Center(
          child: Text(
            'Yükleme hatası:\n${vm.errorMessage}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        );
        break;
      case IngredientStateStatus.ready:
        final data = _visible;
        if (data.isEmpty) {
          body = const Center(child: Text('Hiç kayıt yok / filtre sonucu boş'));
        } else {
          body = ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: data.length,
            itemBuilder: (c, i) => IngredientItemCard(
              ingredient: data[i],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => IngredientDetailScreen(ingredient: data[i])),
                );
              },
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
            icon: Icon(showFilters ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () => setState(() => showFilters = !showFilters),
          )
        ],
      ),
      body: Column(
        children: [
          _SearchBar(controller: controller, onChanged: _onSearch),
          if (showFilters)
            _Filters(
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

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.controller, required this.onChanged});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16,12,16,8),
      child: TextField(
        controller: widget.controller,
        onChanged: (v) {
          setState(() {}); // clear butonunun görünürlüğü
          widget.onChanged(v);
        },
        decoration: InputDecoration(
          hintText: 'İsim / kategori / synonym / E-numara ara...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  })
              : null,
        ),
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
      'bitkisel','hayvansal','mikrobiyal','mineral','sentetik','karışık','bilinmiyor'
    ];
    final risks = ['green','yellow','red'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal:16, vertical: 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: -4,
            children: origins.map((o) {
              final selected = o == selectedOrigin;
              return FilterChip(
                label: Text(o),
                selected: selected,
                onSelected: (_) => onOriginChange(selected ? null : o),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: risks.map((r) {
              final selected = r == riskFilter;
              Color base;
              switch(r){
                case 'green': base = Colors.green; break;
                case 'yellow': base = Colors.amber; break;
                case 'red': base = Colors.red; break;
                default: base = Colors.grey;
              }
              return FilterChip(
                label: Text(r.toUpperCase()),
                selected: selected,
                selectedColor: base.withOpacity(.25),
                backgroundColor: base.withOpacity(.12),
                onSelected: (_) => onRiskChange(selected ? null : r),
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