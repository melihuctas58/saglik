import 'package:flutter/material.dart';
import '../../../core/themes/design_tokens.dart';
import '../../../domain/models/ingredient.dart';

class IngredientCardCompact extends StatelessWidget {
  final Ingredient ingredient;
  final VoidCallback onTap;
  final VoidCallback? onSelectToggle;
  final bool selected;
  const IngredientCardCompact({
    super.key,
    required this.ingredient,
    required this.onTap,
    this.onSelectToggle,
    this.selected = false
  });

  IconData get icon {
    switch (ingredient.core.iconHint) {
      case 'seed': return Icons.grass;
      case 'leaf': return Icons.eco;
      case 'oil': return Icons.oil_barrel_outlined;
      default: return Icons.fastfood;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskCol = riskColor(ingredient.risk.riskLevel);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onLongPress: onSelectToggle,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: selected ? riskCol : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 6,
              offset: const Offset(0,3)
            )
          ]
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: riskCol.withOpacity(.15),
              radius: 26,
              child: Icon(icon, color: riskCol, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ingredient.core.primaryName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(ingredient.core.shortSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: -4,
                    children: [
                      _metaChip(ingredient.core.category),
                      if (ingredient.core.subcategory.isNotEmpty)
                        _metaChip(ingredient.core.subcategory),
                      if (ingredient.classification.originType.isNotEmpty)
                        _metaChip(ingredient.classification.originType),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 8),
            _riskPill(riskCol, ingredient.risk.riskLevel),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(String label) => Chip(
    label: Text(label, style: const TextStyle(fontSize: 10)),
    padding: EdgeInsets.zero,
    visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
  );

  Widget _riskPill(Color c, String level) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.withOpacity(.14),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(level.toUpperCase(),
      style: TextStyle(
        color: c,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: .5
      )),
  );
}