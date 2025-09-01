import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class IngredientBadges extends StatelessWidget {
  final Dietary dietary;
  const IngredientBadges({required this.dietary, super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> badges = [];
    if (dietary.vegan) {
      badges.add(_buildBadge('Vegan', Colors.green, Icons.spa));
    }
    if (dietary.vegetarian) {
      badges.add(_buildBadge('Vejetaryen', Colors.lightGreen, Icons.eco));
    }
    if (dietary.glutenFree) {
      badges.add(_buildBadge('Glutensiz', Colors.blue, Icons.no_food));
    }
    if (dietary.lactoseFree) {
      badges.add(_buildBadge('Laktozsuz', Colors.blueGrey, Icons.icecream));
    }
    if (dietary.halal == 'helal') {
      badges.add(_buildBadge('Helal', Colors.teal, Icons.check));
    }
    if (dietary.kosher) {
      badges.add(_buildBadge('Koşer', Colors.indigo, Icons.star));
    }
    return Wrap(
      spacing: 8,
      children: badges,
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(label),
      backgroundColor: color,
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}