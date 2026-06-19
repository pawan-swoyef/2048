import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../board.dart';

/// Today's saved daily-challenge state: either a finished result, or an
/// in-progress run to resume (its move history).
class DailySaved {
  final bool finished;
  final bool success;
  final int moves;
  final List<Direction> history;

  const DailySaved({
    required this.finished,
    this.success = false,
    this.moves = 0,
    this.history = const [],
  });
}

/// Persists the daily challenge: the in-progress run (so one attempt resumes),
/// today's finished result, and the daily-completion streak.
class DailyStore {
  static const _ipPuzzle = 'daily_ip_puzzle';
  static const _ipTarget = 'daily_ip_target';
  static const _ipMoves = 'daily_ip_moves';
  static const _resPuzzle = 'daily_res_puzzle';
  static const _resSuccess = 'daily_res_success';
  static const _resMoves = 'daily_res_moves';
  static const _streak = 'daily_streak';
  static const _lastPuzzle = 'daily_last_puzzle';

  /// Returns today's saved state, or null if there is none for [todayPuzzle].
  Future<DailySaved?> load(int todayPuzzle) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_resPuzzle) == todayPuzzle) {
      return DailySaved(
        finished: true,
        success: prefs.getBool(_resSuccess) ?? false,
        moves: prefs.getInt(_resMoves) ?? 0,
      );
    }
    if (prefs.getInt(_ipPuzzle) == todayPuzzle) {
      final raw = prefs.getString(_ipMoves) ?? '[]';
      final history = (jsonDecode(raw) as List)
          .map((i) => Direction.values[i as int])
          .toList();
      return DailySaved(finished: false, history: history);
    }
    return null;
  }

  Future<void> saveInProgress(
      int puzzle, int target, List<Direction> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ipPuzzle, puzzle);
    await prefs.setInt(_ipTarget, target);
    await prefs.setString(
        _ipMoves, jsonEncode(history.map((d) => d.index).toList()));
  }

  /// Records the finished result, clears the in-progress run, and updates the
  /// daily-completion streak.
  Future<void> saveResult(int puzzle,
      {required bool success, required int moves}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_resPuzzle, puzzle);
    await prefs.setBool(_resSuccess, success);
    await prefs.setInt(_resMoves, moves);
    await prefs.remove(_ipPuzzle);
    await prefs.remove(_ipTarget);
    await prefs.remove(_ipMoves);

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
