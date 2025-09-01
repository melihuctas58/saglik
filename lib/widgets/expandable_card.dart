import 'package:flutter/material.dart';

class ExpandableCard extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const ExpandableCard({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (_expanded) _ctrl.value = 1;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(widget.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15))),
                  RotationTransition(
                    turns: Tween<double>(begin: 0, end: 0.5).animate(_anim),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
              SizeTransition(
                sizeFactor: _anim,
                axisAlignment: -1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}