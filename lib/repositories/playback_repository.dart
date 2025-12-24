import 'package:shared_preferences/shared_preferences.dart';

class PlaybackRepository {
  static const String _prefix = 'playback_pos_';

  Future<void> savePosition(String url, Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$url', position.inSeconds);
  }

  Future<Duration> getPosition(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt('$_prefix$url') ?? 0;
    return Duration(seconds: seconds);
  }
}
