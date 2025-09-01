import 'package:flutter/material.dart';

class ExpandableSection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final IconData icon;
  const ExpandableSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.icon = Icons.segment
  });

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection> {
  late bool expanded;

  @override
  void initState() {
    super.initState();
    expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(widget.icon, color: Theme.of(context).colorScheme.primary),
              title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: IconButton(
                icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () => setState(()=> expanded = !expanded),
              ),
              onTap: () => setState(()=> expanded = !expanded),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                child: widget.child,
              ),
              crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 280),
              sizeCurve: Curves.easeOut,
            )
          ],
        ),
      ),
    );
  }
}