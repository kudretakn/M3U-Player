import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';

class PlaylistRepository {
  static const String _keyPlaylists = 'playlists';

  Future<List<Playlist>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyPlaylists);
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Playlist.fromJson(json)).toList();
  }

  Future<void> savePlaylist(Playlist playlist) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Playlist> currentPlaylists = await getPlaylists();

    // Check for duplicates (simple check by URL)
    if (!currentPlaylists.any((p) => p.url == playlist.url)) {
      currentPlaylists.add(playlist);
      final String jsonString =
          jsonEncode(currentPlaylists.map((p) => p.toJson()).toList());
      await prefs.setString(_keyPlaylists, jsonString);
    }
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Playlist> currentPlaylists = await getPlaylists();

    currentPlaylists.removeWhere((p) => p.url == playlist.url);
    final String jsonString =
        jsonEncode(currentPlaylists.map((p) => p.toJson()).toList());
    await prefs.setString(_keyPlaylists, jsonString);
  }
}
