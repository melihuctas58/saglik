import 'package:flutter/material.dart';

import '../services/scan_history_service.dart';
import '../models/ingredient.dart';
import '../services/popularity_service.dart';

class RecentScansScreen extends StatefulWidget {
  final ValueChanged<Ingredient> onOpenIngredient;
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

  void _openRecordDetails(ScanRecord rec) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordDetailSheet(
        record: rec,
        onOpenIngredient: widget.onOpenIngredient,
      ),
    );
  }

  String _fmt(DateTime dt) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${two(dt.day)}.${two(dt.month)}.${dt.year % 100} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final records = history.records;
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
                if (records.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => history.clear(),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Temizle'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const Center(child: Text('Henüz tarama yok'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: records.length,
                    itemBuilder: (_, i) {
                      final r = records[i];
                      final formatted = _fmt(r.time);
                      final names = r.ingredients
                          .take(3)
                          .map((e) => e.core.primaryName ?? '')
                          .join(', ');
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          onTap: () => _openRecordDetails(r),
                          title: Text(formatted,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
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
          ),
        ],
      ),
    );
  }
}

class _RecordDetailSheet extends StatelessWidget {
  final ScanRecord record;
  final ValueChanged<Ingredient> onOpenIngredient;
  const _RecordDetailSheet({
    required this.record,
    required this.onOpenIngredient,
  });

  String _fmt(DateTime dt) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E2024),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    _fmt(record.time),
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
                itemCount: record.ingredients.length,
                itemBuilder: (_, i) {
                  final ing = record.ingredients[i];
                  final pop = PopularityService.instance.count(ing);
                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      onOpenIngredient(ing);
                    },
                    title: Text(
                      ing.core.primaryName ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text('Popülerlik: $pop',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.white54),
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