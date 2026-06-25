// Pure logic for the Number Tap Challenge: a 5x5 grid of the numbers 1..25 in
// random order, tapped in ascending order. No IO, no Flutter. The timer lives
// in the UI; this tracks only the tap sequence and mistakes.

import 'dart:math';

class NumberTapGame {
  /// Cell index (0..24) -> the number shown there. Holds exactly 1..25.
  final List<int> board;

  /// The next number expected (starts at 1).
  int next = 1;

  /// Count of wrong taps.
  int mistakes = 0;

  NumberTapGame(Random rng)
      : board = [for (var i = 1; i <= 25; i++) i]..shuffle(rng);

  NumberTapGame._(this.board);

  /// Serializes the tap progress for resume-on-return. The elapsed timer lives
  /// in the UI and is saved alongside this map.
  Map<String, dynamic> toJson() => {
        'board': board,
        'next': next,
        'mistakes': mistakes,
      };

  /// Rebuilds a game from [toJson] output (decoded JSON).
  factory NumberTapGame.fromJson(Map<String, dynamic> json) {
    final game = NumberTapGame._([for (final v in json['board'] as List) v as int]);
    game.next = json['next'] as int;
    game.mistakes = json['mistakes'] as int;
    return game;
  }

  bool get isComplete => next > 25;

  /// Two-second penalty per wrong tap.
  int get penaltySeconds => mistakes * 2;

  /// Whether [number] has already been tapped (for dimming cleared cells).
  bool isCleared(int number) => number < next;

  /// Taps [number]. Advances on the expected number, otherwise counts a
  /// mistake. No-op once the game is complete.
  void tap(int number) {
    if (isComplete) return;
    if (number == next) {
      next++;
    } else {
      mistakes++;
    }
  }
}
