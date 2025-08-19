import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _regionKey = 'selected_region';

  static Future<void> saveRegion(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, region);
  }

  static Future<String> getRegion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_regionKey) ?? 'Global';
  }
}
