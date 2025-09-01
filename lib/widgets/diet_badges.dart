import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class DietBadges extends StatelessWidget {
  final Dietary dietary;
  const DietBadges({super.key, required this.dietary});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (dietary.vegan) chips.add(_chip('Vegan', Colors.green, Icons.spa));
    if (dietary.vegetarian) chips.add(_chip('Vejetaryen', Colors.lightGreen, Icons.eco));
    if (dietary.glutenFree) chips.add(_chip('Glutensiz', Colors.indigo, Icons.no_food));
    if (dietary.lactoseFree) chips.add(_chip('Laktozsuz', Colors.blueGrey, Icons.icecream));
    if (dietary.halal.toLowerCase() == 'helal') chips.add(_chip('Helal', Colors.teal, Icons.check));
    if (dietary.kosher) chips.add(_chip('Koşer', Colors.deepPurple, Icons.star));
    return Wrap(spacing: 8, runSpacing: -4, children: chips);
  }

  Widget _chip(String text, Color color, IconData icon) => Chip(
        avatar: Icon(icon, size: 18, color: Colors.white),
        label: Text(text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      );
}