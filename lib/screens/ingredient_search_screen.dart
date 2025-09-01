import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ingredient.dart';
import '../widgets/ingredient_card.dart';
import 'ingredient_detail_screen.dart';

class IngredientSearchScreen extends StatefulWidget {
  const IngredientSearchScreen({super.key});

  @override
  State<IngredientSearchScreen> createState() => _IngredientSearchScreenState();
}

class _IngredientSearchScreenState extends State<IngredientSearchScreen> {
  List<Ingredient> _ingredients = [];
  List<Ingredient> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    final String data =
        await DefaultAssetBundle.of(context).loadString('assets/malzemeler.json');
    final List<dynamic> jsonList = json.decode(data);
    setState(() {
      _ingredients = jsonList.map((e) => Ingredient.fromJson(e)).toList();
      _filtered = _ingredients;
    });
  }

  void _filterIngredients(String text) {
    setState(() {
      _filtered = _ingredients.where((i) {
        final query = text.toLowerCase();
        return i.core.primaryName.toLowerCase().contains(query) ||
            i.core.names['tr'].toLowerCase().contains(query) ||
            i.core.names['en'].toLowerCase().contains(query) ||
            (i.core.names['synonyms'] as List<dynamic>)
                .map((s) => s.toString().toLowerCase())
                .any((s) => s.contains(query)) ||
            (i.identifiers.eNumber ?? '').toLowerCase().contains(query) ||
            i.core.category.toLowerCase().contains(query) ||
            i.core.subcategory.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Malzeme Arama'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Malzeme, E-numara, kategori veya synonym ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filterIngredients,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('Sonuç bulunamadı.'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) => IngredientCard(
                        ingredient: _filtered[i],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IngredientDetailScreen(ingredient: _filtered[i]),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}