import 'package:shared_preferences/shared_preferences.dart';

import 'daily_engagement.dart';

/// Persists [PlayerProgress] locally via SharedPreferences, mirroring the
/// existing ScoreStore pattern.
class ProgressStore {
  static const _coins = 'coins';
  static const _streakCurrent = 'streak_current';
  static const _streakLongest = 'streak_longest';
  static const _lastActive = 'last_active_date';
  static const _giftClaimed = 'gift_claimed_date';
  static const _freezes = 'streak_freezes';

  Future<PlayerProgress> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PlayerProgress(
      coins: prefs.getInt(_coins) ?? 0,
      streakCurrent: prefs.getInt(_streakCurrent) ?? 0,
      streakLongest: prefs.getInt(_streakLongest) ?? 0,
      lastActiveDate: prefs.getString(_lastActive),
      giftClaimedDate: prefs.getString(_giftClaimed),
      streakFreezes: prefs.getInt(_freezes) ?? 1,
    );
  }

  Future<void> save(PlayerProgress p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coins, p.coins);
    await prefs.setInt(_streakCurrent, p.streakCurrent);
    await prefs.setInt(_streakLongest, p.streakLongest);
    await prefs.setInt(_freezes, p.streakFreezes);
    if (p.lastActiveDate != null) {
      await prefs.setString(_lastActive, p.lastActiveDate!);
    }
    if (p.giftClaimedDate != null) {
      await prefs.setString(_giftClaimed, p.giftClaimedDate!);
    }
  }
}
