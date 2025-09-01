import 'package:flutter/material.dart';
import '../../../core/themes/design_tokens.dart';

class RiskRing extends StatelessWidget {
  final int score; // 0-5000
  final String level;
  final double size;
  const RiskRing({super.key, required this.score, required this.level, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final pct = (score.clamp(0, 5000) / 5000);
    final col = riskColor(level);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: pct,
            strokeWidth: 7,
            backgroundColor: col.withOpacity(.15),
            valueColor: AlwaysStoppedAnimation(col),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text((score).toString(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: col)),
              Text(level.toUpperCase(),
                  style: TextStyle(fontSize: 10, letterSpacing: .5, color: col)),
            ],
          )
        ],
      ),
    );
  }
}