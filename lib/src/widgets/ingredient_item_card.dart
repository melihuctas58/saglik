import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import 'risk_chip.dart';

class IngredientItemCard extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;
  const IngredientItemCard({required this.ingredient, required this.onTap, super.key});

  IconData get icon {
    switch (ingredient.core.iconHint) {
      case 'seed':
        return Icons.grass;
      case 'leaf':
        return Icons.eco;
      case 'oil':
        return Icons.oil_barrel_outlined;
      default:
        return Icons.fastfood;
    }
  }

  Color get riskColor {
    switch (ingredient.risk.labelColor) {
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.amber;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: riskColor.withOpacity(.15),
                child: Icon(icon, color: riskColor, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(ingredient.core.primaryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                              )),
                        ),
                        const SizedBox(width: 6),
                        RiskChip(level: ingredient.risk.riskLevel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ingredient.core.shortSummary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: -6,
                      children: [
                        _miniTag(ingredient.core.category),
                        if (ingredient.core.subcategory.isNotEmpty)
                          _miniTag(ingredient.core.subcategory),
                        if (ingredient.identifiers.eNumber != null)
                          _miniTag('E: ${ingredient.identifiers.eNumber}'),
                        if (ingredient.classification.isAdditive)
                          _miniTag('Katkı'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTag(String text) => Chip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
      );
}