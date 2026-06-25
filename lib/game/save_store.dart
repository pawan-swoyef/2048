import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists an in-progress game so a player who leaves mid-play (Home button,
/// app closed) can resume instead of restarting. Each game serializes its own
/// state to a JSON map; this store just holds the blob under `save_<id>`.
class GameSaveStore {
  static String _key(String id) => 'save_$id';

  /// Writes the in-progress state for [id].
  Future<void> save(String id, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(id), jsonEncode(json));
  }

  /// Reads the saved state for [id], or null if none exists or it is corrupt.
  Future<Map<String, dynamic>?> load(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(id));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Removes any saved state for [id] (called when a game finishes or is reset).
  Future<void> clear(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(id));
  }
}
