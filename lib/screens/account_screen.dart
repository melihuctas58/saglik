import 'package:flutter/material.dart';
import '../services/popularity_service.dart';
import '../services/scan_history_service.dart';

class AccountScreen extends StatelessWidget {
  final List<dynamic> allIngredients;
  final void Function(dynamic) onOpenIngredient;
  const AccountScreen({
    super.key,
    required this.allIngredients,
    required this.onOpenIngredient,
  });

  @override
  Widget build(BuildContext context) {
    final scans = ScanHistoryService.instance.records.length;
    final counts = PopularityService.instance.snapshot();
    final top = _topPopular(allIngredients, 5);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          const Text('Hesap',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _stat(Icons.camera_alt, 'Toplam Tarama', scans.toString(),
              Colors.red.shade600),
          _stat(Icons.storage, 'Malzeme Sayısı', allIngredients.length.toString(),
              Colors.indigo.shade500),
          _stat(Icons.local_fire_department, 'Popülerliği Olan',
              counts.length.toString(), Colors.orange.shade600),
          const SizedBox(height: 18),
          const Text('En Popüler 5',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (top.isEmpty)
            const Text('Veri yok', style: TextStyle(color: Colors.grey)),
          ...top.map((p) => ListTile(
                onTap: () => onOpenIngredient(p.item),
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Text(
                    (p.name.isEmpty ? '?' : p.name[0].toUpperCase()),
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(p.name),
                subtitle: Text('Sayım: ${p.count}'),
                trailing: const Icon(Icons.chevron_right),
              )),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String title, String val, Color c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: c.withOpacity(.25),
            child: Icon(icon, color: c),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14))),
          Text(val,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: c)),
        ],
      ),
    );
  }

  List<_PopItem> _topPopular(List<dynamic> all, int n) {
    final snap = PopularityService.instance.snapshot();
    final tmp = <_PopItem>[];
    for (final ing in all) {
      final name = (ing.core?.primaryName ?? '').toString();
      if (name.isEmpty) continue;
      final k = name.toLowerCase();
      final c = snap[k] ?? 0;
      if (c > 0) tmp.add(_PopItem(item: ing, name: name, count: c));
    }
    tmp.sort((a, b) => b.count.compareTo(a.count));
    return tmp.take(n).toList();
  }
}

class _PopItem {
  final dynamic item;
  final String name;
  final int count;
  _PopItem({required this.item, required this.name, required this.count});
}