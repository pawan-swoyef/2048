import 'package:shared_preferences/shared_preferences.dart';

/// Persists the best score locally on the device.
class ScoreStore {
  static const _key = 'best_score';

  Future<int> loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  Future<void> saveBest(int best) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, best);
  }

  static String _bestKey(String gameId) => 'best_$gameId';

  /// Best score for a specific game id (0 if none). The legacy single
  /// `best_score` key is migrated to the `2048` game id on first read.
  Future<int> bestFor(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getInt(_bestKey(gameId));
    if (existing != null) return existing;
    if (gameId == '2048') {
      final legacy = prefs.getInt(_key);
      if (legacy != null) {
        await prefs.setInt(_bestKey('2048'), legacy);
        return legacy;
      }
    }
    return 0;
  }

  Future<void> saveBestFor(String gameId, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestKey(gameId), value);
  }

  static const _soundKey = 'sound_enabled';

  Future<bool> loadSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  Future<void> saveSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }

  static const _themeKey = 'theme_id';
  static const _premiumKey = 'premium_unlocked';

  Future<String> loadThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'aurora';
  }

  Future<bool> loadPremiumUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  Future<void> saveTheme(String themeId, bool premiumUnlocked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeId);
    await prefs.setBool(_premiumKey, premiumUnlocked);
  }
}
