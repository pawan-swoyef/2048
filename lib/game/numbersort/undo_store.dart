import 'package:shared_preferences/shared_preferences.dart';

import 'undo_allowance.dart';

/// Persists Number Sort's daily free-undo usage: the date the count belongs to
/// and how many free undos have been spent that day. The day-rollover reset is
/// handled by [UndoAllowance]; this layer only reads and writes the raw values.
class UndoStore {
  final String gameId;
  UndoStore({this.gameId = 'numbersort'});

  String get _dateKey => '${gameId}_undo_date';
  String get _usedKey => '${gameId}_undo_used';

  /// Today's allowance for a [premium] (or free) player. [today] is a
  /// `YYYY-MM-DD` string so the caller controls the clock (and tests can fix it).
  Future<UndoAllowance> allowance({
    required bool premium,
    required String today,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return UndoAllowance.forToday(
      premium: premium,
      storedDate: prefs.getString(_dateKey) ?? '',
      storedUsed: prefs.getInt(_usedKey) ?? 0,
      today: today,
    );
  }

  /// Records one spent free undo for [today], resetting first if the stored
  /// count belongs to an earlier day.
  Future<void> recordUndo({required String today}) async {
    final prefs = await SharedPreferences.getInstance();
    final sameDay = prefs.getString(_dateKey) == today;
    final used = sameDay ? (prefs.getInt(_usedKey) ?? 0) : 0;
    await prefs.setString(_dateKey, today);
    await prefs.setInt(_usedKey, used + 1);
  }
}
