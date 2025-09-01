import 'package:flutter/material.dart';

class AllergenBanner extends StatelessWidget {
  final List<String> allergenFlags;
  final String note;
  const AllergenBanner({super.key, required this.allergenFlags, required this.note});

  @override
  Widget build(BuildContext context) {
    if (allergenFlags.isEmpty) return const SizedBox.shrink();
    final color = Colors.red.shade50;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border(left: BorderSide(color: Colors.red.shade400, width: 4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
            const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alerjen Uyarısı',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: allergenFlags
                      .map((f) => Chip(
                          label: Text(f, style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.red.shade100))
                      .toList(),
                ),
                if (note.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(note, style: TextStyle(fontSize: 12, color: Colors.red.shade800)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}