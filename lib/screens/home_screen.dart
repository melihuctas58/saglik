import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../widgets/app_logo.dart';
import 'ingredient_detail_screen.dart';
import 'search_screen.dart';
import '../utils/risk_colors.dart';
import '../utils/risk_labels.dart';

class HomeScreen extends StatelessWidget {
  final List<Ingredient> allIngredients;
  const HomeScreen({
    super.key,
    required this.allIngredients,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: AppLogo(height: 60), // Logo büyütüldü
        ),
        actions: const [], // Sağ üstte ayarlar kaldırıldı
      ),
      body: _body(context, theme),
    );
  }

  Widget _body(BuildContext context, ColorScheme theme) {
    // HER HAFTA FARKLI, O HAFTA İÇİN SABİT "Trendler"
    final trending = _weeklyTrending(allIngredients, 12);

    final categories = <_Category>[
      _Category('Vegan', Icons.eco_outlined, 'vegan'),
      _Category('Vejetaryen', Icons.restaurant_outlined, 'vegetarian'),
      _Category('Glutensiz', Icons.no_food_outlined, 'gluten_free'),
      _Category('Laktozsuz', Icons.free_breakfast_outlined, 'lactose_free'),
      _Category('Helal', Icons.verified_outlined, 'halal'),
      _Category('Katkı', Icons.science_outlined, 'additive'),
    ];
    final catColors = _categoryPalettes(theme);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kategoriler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, idx) {
                final c = categories[idx];
                final palette = catColors[idx % catColors.length];
                return _CategoryCard(
                  title: c.title,
                  icon: c.icon,
                  bg1: palette.$1,
                  bg2: palette.$2,
                  onTap: () {
                    Navigator.of(ctx).push(MaterialPageRoute(
                      builder: (_) => SearchScreen(
                        allIngredients: allIngredients,
                        initialFilters: {c.filterKey},
                      ),
                    ));
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text('Trendler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trending.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final ing = trending[i];
              final score = ing.risk.riskScore;
              final color = riskColorFromScore(score);
              final label = riskLabelFromScore(score);
              return InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => IngredientDetailScreen(ingredient: ing),
                )),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ing.core.primaryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ing.core.shortSummary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: theme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          border: Border.all(color: color.withOpacity(0.35)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  // Epoch haftasına göre seed üretip karıştırır; o hafta içinde sabit kalır.
  List<Ingredient> _weeklyTrending(List<Ingredient> all, int count) {
    if (all.isEmpty) return const [];
    final weekSeed =
        DateTime.now().toUtc().millisecondsSinceEpoch ~/ const Duration(days: 7).inMilliseconds;
    final rnd = Random(weekSeed);
    final list = List<Ingredient>.from(all);
    list.shuffle(rnd);
    return list.take(count).toList();
  }

  Color _riskColorOf(String level, BuildContext context) {
    final l = level.toLowerCase();
    if (l.contains('high') || l.contains('yüksek') || l.contains('red') || l.contains('kırmızı')) {
      return Colors.red;
    }
    if (l.contains('medium') || l.contains('orta') || l.contains('amber') || l.contains('turuncu')) {
      return Colors.amber;
    }
    if (l.contains('low') || l.contains('düşük') || l.contains('green') || l.contains('yeşil') || l.contains('yesil')) {
      return Colors.green;
    }
    return Theme.of(context).colorScheme.outline;
  }

  String _riskLabelOf(String level) {
    final l = level.toLowerCase();
    if (l.contains('high') || l.contains('yüksek')) return 'Yüksek';
    if (l.contains('medium') || l.contains('orta')) return 'Orta';
    if (l.contains('low') || l.contains('düşük')) return 'Düşük';
    return 'Bilinmiyor';
  }

  List<(Color, Color)> _categoryPalettes(ColorScheme scheme) => [
        (scheme.primaryContainer, scheme.secondaryContainer),
        (Colors.teal.shade200, Colors.teal.shade100),
        (Colors.indigo.shade200, Colors.indigo.shade100),
        (Colors.orange.shade200, Colors.orange.shade100),
        (Colors.pink.shade200, Colors.pink.shade100),
        (Colors.blueGrey.shade200, Colors.blueGrey.shade100),
      ];
}

class _Category {
  final String title;
  final IconData icon;
  final String filterKey;
  _Category(this.title, this.icon, this.filterKey);
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color bg1;
  final Color bg2;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.bg1,
    required this.bg2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [bg1, bg2]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}