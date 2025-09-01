import 'package:flutter/material.dart';

class RiskBar extends StatelessWidget {
  final int score; // 0-5000
  final String level;
  const RiskBar({super.key, required this.score, required this.level});

  Color get color {
    switch (level) {
      case 'red': return const Color(0xFFD94343);
      case 'yellow': return const Color(0xFFE8A534);
      case 'green': return const Color(0xFF24A669);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = score.clamp(0, 5000) / 5000;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Risk Skoru: $score', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(height: 14, width: double.infinity, color: Colors.grey.shade200),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                height: 14,
                width: MediaQuery.of(context).size.width * pct,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(.7), color],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('Risk: ${level.toUpperCase()}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}