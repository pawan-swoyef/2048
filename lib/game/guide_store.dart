import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the player has already seen the first-game move guide for a
/// given game id, so the guide shows only during their very first playthrough.
class GuideStore {
  static String _key(String gameId) => 'guide_seen_$gameId';

  /// Whether the guide for [gameId] has already been shown (defaults to false).
  Future<bool> guideSeen(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(gameId)) ?? false;
  }

  /// Records that the guide for [gameId] has been shown.
  Future<void> markGuideSeen(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(gameId), true);
  }
}
