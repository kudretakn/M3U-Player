import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _keyAdultFilter = 'adult_filter_enabled';

  Future<bool> isAdultFilterEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdultFilter) ?? false;
  }

  Future<void> setAdultFilterEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdultFilter, enabled);
  }
}
