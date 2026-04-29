import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();
  static const String _key = 'rakni_favorites';

  Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? {};
  }

  Future<void> toggleFavorite(String lotName) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = prefs.getStringList(_key)?.toSet() ?? {};
    if (favs.contains(lotName)) {
      favs.remove(lotName);
    } else {
      favs.add(lotName);
    }
    await prefs.setStringList(_key, favs.toList());
  }

  Future<bool> isFavorite(String lotName) async {
    final favs = await getFavorites();
    return favs.contains(lotName);
  }
}
