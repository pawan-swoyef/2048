import 'dart:math';

import 'board.dart';

/// Number of rows/columns on the board.
const int kBoardSize = 4;

/// Immutable snapshot of a 2048 game. Every transition returns a new instance,
/// keeping the game logic pure and easy to test.
class GameState {
  /// The 4x4 grid of tile values (0 = empty).
  final List<List<int>> board;

  /// Current score.
  final int score;

  /// Best score seen so far (persisted across games by the UI layer).
  final int best;

  /// Whether a 2048 tile has been reached at least once.
  final bool won;

  /// Whether the player chose to keep playing after winning.
  final bool keepGoing;

  /// Whether no moves remain.
  final bool over;

  const GameState({
    required this.board,
    this.score = 0,
    this.best = 0,
    this.won = false,
    this.keepGoing = false,
    this.over = false,
  });

  /// Starts a fresh game: an empty board seeded with two tiles. [best] is
  /// carried over from previous play.
  factory GameState.newGame(Random rng, {int best = 0}) {
    var board = List.generate(
      kBoardSize,
      (_) => List<int>.filled(kBoardSize, 0),
    );
    board = spawnRandomTile(board, rng);
    board = spawnRandomTile(board, rng);
    return GameState(board: board, best: best);
  }

  /// Applies a swipe. If the board changes, adds the merge score, spawns a new
  /// tile, and recomputes the win/over flags. A no-op move (or a move after the
  /// game is over) returns the same instance unchanged.
  GameState move(Direction dir, Random rng) {
    if (over) return this;

    final result = applyMove(board, dir);
    if (!result.moved) return this;

    final nextBoard = spawnRandomTile(result.board, rng);
    final nextScore = score + result.gainedScore;

    return GameState(
      board: nextBoard,
      score: nextScore,
      best: max(best, nextScore),
      won: won || hasWon(nextBoard),
      keepGoing: keepGoing,
      over: isGameOver(nextBoard),
    );
  }

  /// Returns this state with [best] raised to at least the given value
  /// (used when undoing, so the best score never decreases).
  GameState withBest(int best) => GameState(
        board: board,
        score: score,
        best: best > this.best ? best : this.best,
        won: won,
        keepGoing: keepGoing,
        over: over,
      );

  /// Continues play after a win (dismisses the win overlay).
  GameState keepPlaying() => GameState(
        board: board,
        score: score,
        best: best,
        won: won,
        keepGoing: true,
        over: over,
      );
}
