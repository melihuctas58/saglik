import 'package:flutter/material.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/ingredient_card.dart';
import '../models/ingredient.dart';

class FavoritesScreen extends StatelessWidget {
  final HomeViewModel homeVm;
  const FavoritesScreen({super.key, required this.homeVm});

  @override
  Widget build(BuildContext context) {
    final favs = homeVm.favorites;
    return Scaffold(
      appBar: AppBar(title: const Text('Favoriler')),
      body: favs.isEmpty
          ? Center(
              child: Text('Favori bulunmuyor.',
                  style: TextStyle(color: Colors.grey.shade600)),
            )
          : ListView.builder(
              itemCount: favs.length,
              itemBuilder: (_, i) => IngredientCard(
                ingredient: favs[i],
                onTap: () => Navigator.pushNamed(context, '/detail', arguments: favs[i]),
              ),
            ),
    );
  }
}