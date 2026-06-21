import 'package:shared_preferences/shared_preferences.dart';

import 'hint_allowance.dart';

/// Persists Magic Square's daily ad-hint usage: the date the count belongs to
/// and how many ad-hints have been spent that day. The day-rollover reset is
/// handled by [HintAllowance]; this layer only reads and writes the raw values.
class HintStore {
  static const _dateKey = 'magicsquare_hint_date';
  static const _usedKey = 'magicsquare_hint_used';

  /// Today's allowance for a [premium] (or free) player. [today] is a
  /// `YYYY-MM-DD` string so the caller controls the clock (and tests can fix it).
  Future<HintAllowance> allowance({
    required bool premium,
    required String today,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return HintAllowance.forToday(
      premium: premium,
      storedDate: prefs.getString(_dateKey) ?? '',
      storedUsed: prefs.getInt(_usedKey) ?? 0,
      today: today,
    );
  }

  /// Records one spent ad-hint for [today], resetting first if the stored count
  /// belongs to an earlier day.
  Future<void> recordHint({required String today}) async {
    final prefs = await SharedPreferences.getInstance();
    final sameDay = prefs.getString(_dateKey) == today;
    final used = sameDay ? (prefs.getInt(_usedKey) ?? 0) : 0;
    await prefs.setString(_dateKey, today);
    await prefs.setInt(_usedKey, used + 1);
  }
}
