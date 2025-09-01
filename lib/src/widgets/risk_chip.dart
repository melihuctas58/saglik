import 'package:flutter/material.dart';

class RiskChip extends StatelessWidget {
  final String level;
  const RiskChip({required this.level, super.key});

  Color get color {
    switch (level) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.amber;
      case 'green':
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(level.toUpperCase(),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.darken())),
      backgroundColor: color.withOpacity(.18),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    );
  }
}

extension _ColorX on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}