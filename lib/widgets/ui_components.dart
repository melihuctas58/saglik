import 'package:flutter/material.dart';
import 'package:flutter/services.dart' ; // Clipboard için

class CardBlock extends StatelessWidget {
  final String title;
  final Widget child;
  const CardBlock({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineVariant),
        boxShadow: [BoxShadow(color: c.shadow.withOpacity(.03), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class ExpandableSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  const ExpandableSection({super.key, required this.title, required this.child, this.initiallyExpanded = false});

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _open,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          children: [widget.child],
          onExpansionChanged: (v) => setState(() => _open = v),
        ),
      ),
    );
  }
}

class PillChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool small;
  const PillChip({super.key, required this.label, required this.color}) : small = false;
  const PillChip.small({super.key, required this.label, required this.color}) : small = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 10 : 12, vertical: small ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.30)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: small ? 12 : 13)),
    );
  }
}

// Daha küçük etiket (üst bilgi alanı için)
class TinyPill extends StatelessWidget {
  final String label;
  final Color color;
  const TinyPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}

// Düz, renksiz küçük etiketler
class TinyTag extends StatelessWidget {
  final String label;
  const TinyTag(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class Label extends StatelessWidget {
  final String label;
  const Label({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label),
    );
  }
}

class MetricBar extends StatelessWidget {
  final String label;
  final double value; // gerçek değer
  final double max; // örn. 4000
  final String? suffix;
  final Color color;
  const MetricBar({super.key, required this.label, required this.value, required this.max, this.suffix, required this.color});

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.outlineVariant;
    // FIX: clamp double ve cast
    final double frac = (value / (max <= 0 ? 1 : max)).clamp(0.0, 1.0) as double;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          if (suffix != null) Text(suffix!, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Container(color: track),
                FractionallySizedBox(
                  widthFactor: frac,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color.withOpacity(.8), color]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class KVRow extends StatelessWidget {
  final String label;
  final String value;
  const KVRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: muted))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class MythFactTile extends StatelessWidget {
  final String myth;
  final String fact;
  const MythFactTile({super.key, required this.myth, required this.fact});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mit', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(myth),
          const SizedBox(height: 8),
          const Text('Gerçek', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(fact),
        ],
      ),
    );
  }
}

class SourceTile extends StatelessWidget {
  final String name;
  final String? url;
  final String? note;
  const SourceTile({super.key, required this.name, this.url, this.note});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.link, size: 18),
      title: Text(name),
      subtitle: (note != null && note!.isNotEmpty) ? Text(note!) : null,
      trailing: (url != null && url!.isNotEmpty)
          ? IconButton(
              tooltip: 'Linki kopyala',
              icon: Icon(Icons.copy_all, color: c.primary),
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: url!));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link kopyalandı.')));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kopyalanamadı.')));
                  }
                }
              },
            )
          : null,
    );
  }
}