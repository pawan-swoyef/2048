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
