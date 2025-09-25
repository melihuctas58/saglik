import 'package:flutter/material.dart';

// Metin işleyici:
// - \n: yeni satır
// - "**Başlık:** ..." -> mini başlık + aynı satırın devamı paragraf
// - "**Başlık**" (tek başına) -> mini başlık
// - "- " ile başlayan satırlar -> madde imi
class SummaryRenderer extends StatelessWidget {
  final String text;
  const SummaryRenderer({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lines = text.split('\n');
    final widgets = <Widget>[];

    final prefixHeadRe = RegExp(r'^\s*\*\*(.+?)\*\*\s*:?\s*(.*)$');

    for (final raw in lines) {
      final line = raw.replaceAll('\r', '');
      final trimmed = line.trimRight();

      if (trimmed.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // 1) Satır başında kalın başlık + opsiyonel devam
      final m = prefixHeadRe.firstMatch(trimmed);
      if (m != null) {
        final head = (m.group(1) ?? '').trim();
        final rest = (m.group(2) ?? '').trim();
        if (head.isNotEmpty) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Text(
              head,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                fontSize: 14.5,
              ),
            ),
          ));
        }
        if (rest.isNotEmpty) {
          widgets.add(Text(
            rest,
            style: TextStyle(color: cs.onSurface, fontSize: 14),
          ));
        }
        continue;
      }

      // 2) Madde imi
      if (trimmed.trimLeft().startsWith('- ')) {
        widgets.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('•', style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                trimmed.trimLeft().substring(2),
                style: TextStyle(color: cs.onSurface, fontSize: 14),
              ),
            ),
          ],
        ));
        widgets.add(const SizedBox(height: 4));
        continue;
      }

      // 3) Düz paragraf
      widgets.add(Text(
        trimmed,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}