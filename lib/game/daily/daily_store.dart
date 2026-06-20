import 'package:shared_preferences/shared_preferences.dart';

/// Today's finished daily-challenge result. A non-null instance means the day's
/// puzzle is done; there is no mid-run resume.
class DailySaved {
  final bool success;

  /// The day's score: moves for move-based games, deciseconds for timed ones.
  final int score;

  const DailySaved({required this.success, required this.score});
}

/// Persists the daily challenge: today's finished result and the
/// daily-completion streak. (No in-progress state — leaving restarts the day.)
class DailyStore {
  static const _resPuzzle = 'daily_res_puzzle';
  static const _resSuccess = 'daily_res_success';
  static const _resScore = 'daily_res_score';
  static const _streak = 'daily_streak';
  static const _lastPuzzle = 'daily_last_puzzle';

  /// Today's finished result for [todayPuzzle], or null if not finished.
  Future<DailySaved?> load(int todayPuzzle) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_resPuzzle) == todayPuzzle) {
      return DailySaved(
        success: prefs.getBool(_resSuccess) ?? false,
        score: prefs.getInt(_resScore) ?? 0,
      );
    }
    return null;
  }

  /// Records the finished result and updates the daily-completion streak.
  Future<void> saveResult(int puzzle,
      {required bool success, required int score}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_resPuzzle, puzzle);
    await prefs.setBool(_resSuccess, success);
    await prefs.setInt(_resScore, score);

    if (success) {
      final last = prefs.getInt(_lastPuzzle);
      final current = prefs.getInt(_streak) ?? 0;
      final next = last == puzzle
          ? current
          : last == puzzle - 1
              ? current + 1
              : 1;
      await prefs.setInt(_streak, next);
      await prefs.setInt(_lastPuzzle, puzzle);
    } else {
      await prefs.setInt(_streak, 0);
    }
  }

  Future<int> dailyStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streak) ?? 0;
  }
}
