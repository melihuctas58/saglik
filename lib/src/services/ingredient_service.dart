import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/ingredient.dart';

class IngredientService {
  static final IngredientService _instance = IngredientService._internal();
  factory IngredientService() => _instance;
  IngredientService._internal();

  List<Ingredient>? _cache;

  Future<List<Ingredient>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/malzemeler.json');
    final decoded = json.decode(raw);
    if (decoded is! List) {
      throw FormatException('JSON root liste değil (beklenen [...])');
    }

    final parsed = <Ingredient>[];
    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is! Map) {
        throw FormatException('Index $i map değil');
      }
      try {
        parsed.add(Ingredient.fromJson(item.cast<String, dynamic>()));
      } catch (e) {
        // Hangi item bozuk görmek için logla
        print('PARSE HATA index=$i id=${item['id']} -> $e');
        rethrow;
      }
    }
    _cache = parsed;
    return _cache!;
  }
}