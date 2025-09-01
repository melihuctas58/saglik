import 'package:flutter/material.dart';

import '../services/scan_history_service.dart';
import '../services/popularity_service.dart';

class RecentScansScreen extends StatefulWidget {
  final void Function(dynamic) onOpenIngredient;
  const RecentScansScreen({super.key, required this.onOpenIngredient});

  @override
  State<RecentScansScreen> createState() => _RecentScansScreenState();
}

class _RecentScansScreenState extends State<RecentScansScreen> {
  final history = ScanHistoryService.instance;

  @override
  void initState() {
    super.initState();
    history.addListener(_listener);
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    history.removeListener(_listener);
    super.dispose();
  }

  String _short(DateTime d) {
    String t(int v) => v < 10 ? '0$v' : '$v';
    return '${t(d.day)}.${t(d.month)}.${d.year % 100}  ${t(d.hour)}:${t(d.minute)}';
  }

  void _openSheet(ScanRecord rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordSheet(rec: rec, onOpenIngredient: widget.onOpenIngredient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recs = history.records;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Text('Son Taramalar',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (recs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => history.clear(),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Temizle'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: recs.isEmpty
                ? const Center(child: Text('Henüz tarama yok'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    itemCount: recs.length,
                    itemBuilder: (_, i) {
                      final r = recs[i];
                      final names = r.items
                          .take(3)
                          .map((e) => e.core?.primaryName ?? '')
                          .join(', ');
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          onTap: () => _openSheet(r),
                          title: Text(_short(r.time),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            names.isEmpty ? '(Malzeme yok)' : names,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

class _RecordSheet extends StatelessWidget {
  final ScanRecord rec;
  final void Function(dynamic) onOpenIngredient;
  const _RecordSheet({required this.rec, required this.onOpenIngredient});

  String _long(DateTime d) {
    String t(int v) => v < 10 ? '0$v' : '$v';
    return '${t(d.day)}.${t(d.month)}.${d.year}  ${t(d.hour)}:${t(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .65,
      maxChildSize: .95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E2024),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    _long(rec.time),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: rec.items.length,
                itemBuilder: (_, i) {
                  final ing = rec.items[i];
                  final pop = PopularityService.instance.count(
                    ing,
                    keyFn: (x) =>
                        (x.core?.primaryName ?? '').toString().toLowerCase(),
                  );
                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      onOpenIngredient(ing);
                    },
                    title: Text(
                      ing.core?.primaryName ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text('Popülerlik: $pop',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right,
                        color: Colors.white54),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}