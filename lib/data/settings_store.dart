import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Lightweight device preferences. Teams and training remain in SQLite.
class SettingsStore {
  const SettingsStore();

  Future<AppPreferences> read() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(
      darkMode: prefs.getBool('poketran.darkMode') ?? true,
      showHints: prefs.getBool('poketran.showHints') ?? true,
    );
  }

  Future<void> save(String key, bool value) async {
    if (key != 'darkMode' && key != 'showHints') {
      throw const ValidationException('Unknown setting.');
    }
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setBool('poketran.$key', value);
    if (!success) {
      throw const ValidationException('Could not save this setting.');
    }
  }
}
