import 'package:shared_preferences/shared_preferences.dart';

class FavoritesRepository {
  static const String _keyFavorites = 'favorite_channels';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFavorites) ?? [];
  }

  Future<void> addFavorite(String channelUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_keyFavorites) ?? [];
    if (!favorites.contains(channelUrl)) {
      favorites.add(channelUrl);
      await prefs.setStringList(_keyFavorites, favorites);
    }
  }

  Future<void> removeFavorite(String channelUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_keyFavorites) ?? [];
    favorites.remove(channelUrl);
    await prefs.setStringList(_keyFavorites, favorites);
  }

  Future<bool> isFavorite(String channelUrl) async {
    final favorites = await getFavorites();
    return favorites.contains(channelUrl);
  }
}
