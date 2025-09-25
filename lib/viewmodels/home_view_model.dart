import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/ingredient.dart';
import '../services/ingredient_index_service.dart';

enum HomeStatus { loading, ready, error }

class HomeViewModel extends ChangeNotifier {
  final IngredientIndexService indexService;

  HomeStatus status = HomeStatus.loading;
  List<Ingredient> all = [];

  HomeViewModel({required this.indexService}) {
    _load();
  }

  Future<void> _load() async {
    status = HomeStatus.loading;
    notifyListeners();
    try {
      // Önce yeni dosya
      final raw = await rootBundle.loadString('assets/malzemeler.json');
      final List<dynamic> arr = jsonDecode(raw) as List<dynamic>;
      all = arr.map((j) => Ingredient.fromJson(j as Map<String, dynamic>)).toList();
      indexService.buildIndex(all);
      status = HomeStatus.ready;
      notifyListeners();
    } catch (e) {
      // Hata durumunda eski dosyaya fallback
      debugPrint('malzemeler.json parse hatası: $e — malzemelereski.json deneniyor...');
      try {
        final rawOld = await rootBundle.loadString('assets/malzemelereski.json');
        final List<dynamic> arrOld = jsonDecode(rawOld) as List<dynamic>;
        all = arrOld.map((j) => Ingredient.fromJson(j as Map<String, dynamic>)).toList();
        indexService.buildIndex(all);
        status = HomeStatus.ready;
        notifyListeners();
      } catch (e2) {
        debugPrint('malzemelereski.json da yüklenemedi: $e2');
        status = HomeStatus.error;
        notifyListeners();
      }
    }
  }
}