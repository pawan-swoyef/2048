import 'package:shared_preferences/shared_preferences.dart';

/// Decides *when* to show the soft review prompt so we ask at a rewarding
/// moment and never nag: only after a few successful daily clears, at most once
/// per [cooldownDays], and never again once the player has rated.
///
/// (The native rating sheet itself is also rate-limited by the OS; this just
/// gates our own pre-prompt card.)
class ReviewStore {
  static const _wins = 'review_daily_wins';
  static const _lastAsked = 'review_last_asked'; // yyyy-MM-dd
  static const _rated = 'review_rated';

  /// Ask only after at least this many successful daily completions.
  static const int minWins = 3;

  /// Then ask again at most once every this many days.
  static const int cooldownDays = 45;

  /// Counts one more successful daily completion.
  Future<void> recordDailyWin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wins, (prefs.getInt(_wins) ?? 0) + 1);
  }

  /// Whether to show the prompt on [today].
  Future<bool> shouldAsk(DateTime today) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_rated) ?? false) return false;
    if ((prefs.getInt(_wins) ?? 0) < minWins) return false;
    final last = prefs.getString(_lastAsked);
    if (last == null) return true;
    return _daysBetween(_parse(last), today) >= cooldownDays;
  }

  /// Records that the prompt was shown on [today] (starts the cooldown).
  Future<void> markAsked(DateTime today) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAsked, _key(today));
  }

  /// Records that the player rated — never prompt again.
  Future<void> markRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rated, true);
  }

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _parse(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  static int _daysBetween(DateTime a, DateTime b) =>
      DateTime(b.year, b.month, b.day)
          .difference(DateTime(a.year, a.month, a.day))
          .inDays;
}
