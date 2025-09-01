import 'dart:async';
import 'package:flutter/material.dart';

import '../services/popularity_service.dart';
import '../utils/category_helper.dart';

class HomeScreen extends StatefulWidget {
  final List<dynamic> allIngredients;
  final void Function(dynamic) onOpenDetail;
  final VoidCallback onOpenSettings;
  final VoidCallback onTapScan;
  const HomeScreen({
    super.key,
    required this.allIngredients,
    required this.onOpenDetail,
    required this.onOpenSettings,
    required this.onTapScan,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum SortMode { popularity, az, za }

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchC = TextEditingController();
  Timer? _deb;
  String _query = '';
  IngredientCategory? _selectedCat;
  SortMode _sort = SortMode.popularity;

  @override
  void initState() {
    super.initState();
    _searchC.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchC.removeListener(_onSearch);
    _searchC.dispose();
    _deb?.cancel();
    super.dispose();
  }

  void _onSearch() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 250), () {
      setState(() => _query = _searchC.text.trim().toLowerCase());
    });
  }

  List<dynamic> _filtered() {
    var list = List<dynamic>.from(widget.allIngredients);

    if (_selectedCat != null) {
      list = list.where((ing) => CategoryHelper.match(ing, _selectedCat!)).toList();
    }

    if (_query.isNotEmpty) {
      list = list.where((ing) {
        final name = (ing.core?.primaryName ?? '').toString().toLowerCase();
        if (name.contains(_query)) return true;
        final namesMap = ing.core?.names;
        if (namesMap is Map) {
          bool hit = false;
          namesMap.forEach((_, v) {
            if (hit) return;
            if (v is String && v.toLowerCase().contains(_query)) hit = true;
            else if (v is List) {
              for (final s in v) {
                if (s.toString().toLowerCase().contains(_query)) {
                  hit = true;
                  break;
                }
              }
            }
          });
          if (hit) return true;
        }
        return false;
      }).toList();
    }

    switch (_sort) {
      case SortMode.popularity:
        list.sort((a, b) =>
            PopularityService.instance
                .count(b, keyFn: (x) => (x.core?.primaryName ?? '').toString().toLowerCase())
                .compareTo(
                    PopularityService.instance.count(a, keyFn: (x) => (x.core?.primaryName ?? '').toString().toLowerCase())));
        break;
      case SortMode.az:
        list.sort((a, b) => (a.core?.primaryName ?? '')
            .toString()
            .compareTo((b.core?.primaryName ?? '').toString()));
        break;
      case SortMode.za:
        list.sort((a, b) => (b.core?.primaryName ?? '')
            .toString()
            .compareTo((a.core?.primaryName ?? '').toString()));
        break;
    }
    return list;
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: _sort,
        onSelect: (m) {
          setState(() => _sort = m);
          Navigator.pop(context);
        },
        onReset: () {
          setState(() {
            _sort = SortMode.popularity;
            _selectedCat = null;
            _searchC.clear();
            _query = '';
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered();
    final top = PopularityService.instance.topN(
      widget.allIngredients,
      5,
      keyFn: (x) => (x.core?.primaryName ?? '').toString().toLowerCase(),
    );

    return SafeArea(
      child: Column(
        children: [
          _header(),
          _searchBar(),
          _categoryBar(),
          if (top.isNotEmpty) _popularSection(top),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Sonuç yok'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final ing = list[i];
                      return _rowItem(ing);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          const Text('Ana Ekran',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: widget.onOpenSettings,
          )
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchC,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Ara...',
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _openSortSheet,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.tune, color: Colors.red),
            ),
          )
        ],
      ),
    );
  }

  Widget _categoryBar() {
    final cats = IngredientCategory.values;
    return SizedBox(
      height: 46,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        children: [
          for (final c in cats)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(CategoryHelper.label(c)),
                selected: _selectedCat == c,
                onSelected: (_) {
                  setState(() {
                    if (_selectedCat == c) {
                      _selectedCat = null;
                    } else {
                      _selectedCat = c;
                    }
                  });
                },
              ),
            )
        ],
      ),
    );
  }

  Widget _popularSection(List<dynamic> list) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Popüler İlk 5',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SizedBox(
            height: 135,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              itemBuilder: (_, i) {
                final ing = list[i];
                final name = (ing.core?.primaryName ?? '').toString();
                final count = PopularityService.instance.count(
                  ing,
                  keyFn: (x) =>
                      (x.core?.primaryName ?? '').toString().toLowerCase(),
                );
                return GestureDetector(
                  onTap: () => widget.onOpenDetail(ing),
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 6,
                          color: Colors.black.withOpacity(.06),
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.trending_up,
                                size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text('$count'),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _rowItem(dynamic ing) {
    final name = (ing.core?.primaryName ?? '').toString();
    final risk = (ing.risk?.riskLevel ?? '').toString();
    final pop = PopularityService.instance.count(
      ing,
      keyFn: (x) => (x.core?.primaryName ?? '').toString().toLowerCase(),
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => widget.onOpenDetail(ing),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.red.shade100,
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _riskBadge(risk),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(pop.toString(),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _riskBadge(String level) {
    Color c;
    switch (level.toLowerCase()) {
      case 'high':
      case 'yüksek':
        c = Colors.red.shade600;
        break;
      case 'medium':
      case 'orta':
        c = Colors.orange.shade600;
        break;
      case 'low':
      case 'düşük':
        c = Colors.green.shade600;
        break;
      default:
        c = Colors.blueGrey.shade500;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(.15),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        level.isEmpty ? 'N/A' : level,
        style: TextStyle(
            fontSize: 11, color: c, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  final SortMode current;
  final void Function(SortMode) onSelect;
  final VoidCallback onReset;
  const _SortSheet(
      {required this.current, required this.onSelect, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .45,
      maxChildSize: .85,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E2024),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sırala',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18)),
            const SizedBox(height: 12),
            _radio(context, 'Popülerlik', SortMode.popularity),
            _radio(context, 'A → Z', SortMode.az),
            _radio(context, 'Z → A', SortMode.za),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Sıfırla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _radio(BuildContext ctx, String label, SortMode mode) {
    final sel = current == mode;
    return InkWell(
      onTap: () => onSelect(mode),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
                color: sel ? Colors.red.shade400 : Colors.white54),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: sel ? Colors.red.shade200 : Colors.white70,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}