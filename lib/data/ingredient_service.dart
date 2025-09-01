import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/ingredient.dart';

class IngredientService {
  static final IngredientService _instance = IngredientService._();
  factory IngredientService() => _instance;
  IngredientService._();

  List<Ingredient>? _cache;

  Future<List<Ingredient>> loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/malzemeler.json');
    final decoded = json.decode(raw);
    if (decoded is! List) throw FormatException('Root JSON liste değil');
    final list = <Ingredient>[];
    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is! Map) {
        throw FormatException('Index $i map değil');
      }
      try {
        list.add(Ingredient.fromJson(item.cast<String, dynamic>()));
      } catch (e) {
        // Hangi item patlıyor görmek için:
        print('PARSE HATA index=$i id=${item['id']} -> $e');
        rethrow;
      }
    }
    _cache = list;
    return list;
  }
}