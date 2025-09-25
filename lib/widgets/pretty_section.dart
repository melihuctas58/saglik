import 'package:flutter/material.dart';

class PrettySection extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final IconData icon;

  const PrettySection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.icon = Icons.segment,
  });

  @override
  State<PrettySection> createState() => _PrettySectionState();
}

class _PrettySectionState extends State<PrettySection>
    with SingleTickerProviderStateMixin {
  late bool _open;
  late AnimationController _ctrl;
  late Animation<double> _size;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _size = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (_open) _ctrl.value = 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _open ? cs.surfaceVariant.withOpacity(.35) : cs.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.expand_more, color: cs.onSurface),
                  ),
                ],
              ),
            ),
            // Body
            SizeTransition(
              sizeFactor: _size,
              axisAlignment: -1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}