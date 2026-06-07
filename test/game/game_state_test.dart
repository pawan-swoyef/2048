import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/board.dart';
import 'package:game2048/game/game_state.dart';

int _countNonZero(List<List<int>> board) =>
    board.expand((row) => row).where((v) => v != 0).length;

void main() {
  group('GameState.newGame', () {
    test('starts with exactly two tiles, zero score, and carried-over best', () {
      final state = GameState.newGame(Random(1), best: 500);

      expect(_countNonZero(state.board), 2);
      expect(state.score, 0);
      expect(state.best, 500);
      expect(state.won, isFalse);
      expect(state.over, isFalse);
      expect(state.keepGoing, isFalse);
    });

    test('every starting tile is a 2 or a 4', () {
      final state = GameState.newGame(Random(7));
      final values = state.board.expand((r) => r).where((v) => v != 0);
      for (final v in values) {
        expect(v == 2 || v == 4, isTrue);
      }
    });
  });

  group('GameState.move', () {
    test('applies the move, adds the merge score, and spawns one tile', () {
      final state = GameState(
        board: const [
          [2, 2, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
      );

      final next = state.move(Direction.left, Random(3));

      expect(next.board[0][0], 4, reason: 'the 2+2 merge lands at top-left');
      expect(next.score, 4);
      expect(_countNonZero(next.board), 2,
          reason: 'one merged tile plus one spawned tile');
    });

    test('updates best when score overtakes the previous best', () {
      final state = GameState(
        board: const [
          [2, 2, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
        best: 3,
      );

      final next = state.move(Direction.left, Random(3));
      expect(next.best, 4);
    });

    test('a no-op move returns an unchanged state and spawns nothing', () {
      final board = const [
        [2, 4, 8, 16],
        [4, 8, 16, 32],
        [8, 16, 32, 64],
        [16, 32, 64, 128],
      ];
      final state = GameState(board: board, score: 99, best: 200);

      final next = state.move(Direction.left, Random(3));

      expect(next.board, board);
      expect(next.score, 99);
      expect(_countNonZero(next.board), 16);
    });

    test('sets won when a tile reaches 2048', () {
      final state = GameState(
        board: const [
          [1024, 1024, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
      );

      final next = state.move(Direction.left, Random(3));
      expect(next.won, isTrue);
      expect(next.score, 2048);
    });

    test('sets over when the move leaves no possible moves', () {
      // Moving up merges the last column (8+8 -> 16), freeing only cell (3,3);
      // whatever value (2 or 4) spawns there, the full board has no merges left.
      final state = GameState(
        board: const [
          [8, 16, 8, 16],
          [16, 32, 16, 32],
          [8, 16, 8, 8],
          [16, 32, 16, 8],
        ],
      );

      final next = state.move(Direction.up, Random(3));
      expect(next.score, 16);
      expect(next.over, isTrue);
    });

    test('is a no-op once the game is over', () {
      final state = GameState(
        board: const [
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2],
        ],
        over: true,
      );

      final next = state.move(Direction.left, Random(3));
      expect(identical(next, state), isTrue);
    });
  });

  group('GameState.withBest', () {
    test('raises best when the given value is higher', () {
      const state = GameState(board: [
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], score: 10, best: 50);

      final result = state.withBest(80);
      expect(result.best, 80);
      expect(result.score, 10);
      expect(result.board, state.board);
    });

    test('keeps the current best when the given value is lower', () {
      const state = GameState(board: [
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ], score: 10, best: 50);

      expect(state.withBest(30).best, 50);
    });
  });

  group('GameState.keepPlaying', () {
    test('marks the game as continued after a win', () {
      final state = GameState(
        board: const [
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
        won: true,
      );

      expect(state.keepPlaying().keepGoing, isTrue);
    });
  });
}
