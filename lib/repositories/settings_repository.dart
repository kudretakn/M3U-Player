import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _keyAdultFilter = 'adult_filter_enabled';
  static const String _keyEpgUrl = 'epg_url';

  Future<bool> isAdultFilterEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdultFilter) ?? false;
  }

  Future<void> setAdultFilterEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdultFilter, value);
  }

  Future<void> saveEpgUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEpgUrl, url);
  }

  Future<String?> getEpgUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEpgUrl);
  }
}
