import 'package:flutter/material.dart';

import 'daily_play_controller.dart';
import 'games/game_2048_daily.dart';

/// The big result-card stat for a finished daily (label / value / optional sub).
typedef DailyResultStat = ({String label, String value, String? sub});

/// Describes one game in the daily rotation: its hero metadata, its seeded play
/// surface, and how to format its live metric and final result.
abstract class DailyGame {
  String get id; // matches a kDailyRotation entry
  String get title; // "2048"
  String get emoji; // hero deco glyph
  Color get accent; // hero gradient base
  String get goalText; // "Reach 512 in the fewest moves"
  String get goalChip; // short hero chip, e.g. "🎯 512"
  String get metricLabel; // "Moves" | "Time"

  /// Formats a metric/score value for display ("8" or "12.4s").
  String formatMetric(int value);

  /// The result-card headline, e.g. "Great job! 🎉" / "Out of moves".
  String resultHeadline(bool success);

  /// The result-card big stat for a finished game.
  DailyResultStat resultStat(bool success, int score);

  /// The share-line result fragment, e.g. "🎯512 in 31 moves".
  String shareResult(bool success, int score);

  /// Whether the result card should celebrate (crown + confetti).
  bool celebrateOn(bool success) => success;

  /// Builds the header-less play surface, seeded by [seed], reporting to
  /// [controller].
  Widget buildPlay(int seed, DailyPlayController controller);
}

/// All daily games, keyed by id. Games are added here as they are implemented;
/// the Daily screen falls back to '2048' for any id not yet present.
final Map<String, DailyGame> kDailyGames = Map.unmodifiable({
  '2048': Game2048Daily(),
});
