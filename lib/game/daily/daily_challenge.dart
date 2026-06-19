// The daily challenge: reach the target tile in the fewest moves on a
// date-seeded 2048 board. Pure (no IO/Flutter). Determinism — and therefore
// resume — relies on replaying the same move history against the same seed,
// since a Random's stream position can't be serialized.

import 'dart:math';

import '../board.dart';
import '../game_state.dart';

enum DailyStatus { playing, won, lost }

class DailyChallenge {
  final int seed;
  final int puzzleNumber;
  final int target;

  final Random _rng;
  final List<Direction> history = [];

  late GameState state;
  DailyStatus status = DailyStatus.playing;

  DailyChallenge({
    required this.seed,
    required this.puzzleNumber,
    this.target = 512,
  }) : _rng = Random(seed) {
    state = GameState.newGame(_rng);
    _checkEnd();
  }

  /// Number of board-changing moves made so far.
  int get moves => history.length;

  /// Applies a swipe. No-ops (and moves after the game ends) are ignored.
  void move(Direction dir) {
    if (status != DailyStatus.playing) return;
    final next = state.move(dir, _rng);
    if (identical(next, state)) return; // no-op: board unchanged
    state = next;
    history.add(dir);
    _checkEnd();
  }

  void _checkEnd() {
    if (_reachedTarget()) {
      status = DailyStatus.won;
    } else if (state.over) {
      status = DailyStatus.lost;
    }
  }

  bool _reachedTarget() {
    for (final row in state.board) {
      for (final v in row) {
        if (v >= target) return true;
      }
    }
    return false;
  }
}
