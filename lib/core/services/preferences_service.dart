import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _regionKey = 'selected_region';
  static const String _feedOptionsPromptShownKey = 'feed_options_prompt_shown';

  static Future<void> saveRegion(String region) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_regionKey, region);
  }

  static Future<String> getRegion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_regionKey) ?? 'Global';
  }

  static Future<bool> hasSeenFeedOptionsPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_feedOptionsPromptShownKey) ?? false;
  }

  static Future<void> markFeedOptionsPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_feedOptionsPromptShownKey, true);
  }
}
