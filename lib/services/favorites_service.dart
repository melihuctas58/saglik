import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'favorite_ingredient_ids';
  static final FavoritesService _instance = FavoritesService._();
  FavoritesService._();
  factory FavoritesService() => _instance;

  List<String> _cache = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cache = prefs.getStringList(_key) ?? [];
  }

  List<String> get favorites => List.unmodifiable(_cache);

  bool isFavorite(String id) => _cache.contains(id);

  Future<void> toggle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (_cache.contains(id)) {
      _cache.remove(id);
    } else {
      _cache.add(id);
    }
    await prefs.setStringList(_key, _cache);
  }
}