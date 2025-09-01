import 'package:flutter/material.dart';
import '../utils/text_format.dart';

class AllergenBanner extends StatelessWidget {
  final List<String> allergenFlags;
  final String note;
  const AllergenBanner({super.key, required this.allergenFlags, required this.note});

  @override
  Widget build(BuildContext context) {
    if (allergenFlags.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: Colors.red.shade400, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
            const SizedBox(width: 8),
            Text('Alerjen Uyarısı',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.red.shade700)),
          ]),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: allergenFlags
                .map((f) => Chip(
                      label: Text(prettifyLabel(f), style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.red.shade100,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                note,
                style: TextStyle(fontSize: 12, color: Colors.red.shade800),
              ),
            ),
        ],
      ),
    );
  }
}