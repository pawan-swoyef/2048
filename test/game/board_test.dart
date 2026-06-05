import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/board.dart';

void main() {
  group('slideLeft', () {
    test('merges two equal adjacent tiles into one doubled tile', () {
      final result = slideLeft([2, 2, 0, 0]);
      expect(result.tiles, [4, 0, 0, 0]);
      expect(result.gainedScore, 4);
    });

    test('compacts tiles left without merging when values differ', () {
      final result = slideLeft([0, 2, 0, 4]);
      expect(result.tiles, [2, 4, 0, 0]);
      expect(result.gainedScore, 0);
    });

    test('merges tiles that become adjacent after compaction', () {
      final result = slideLeft([2, 0, 2, 0]);
      expect(result.tiles, [4, 0, 0, 0]);
      expect(result.gainedScore, 4);
    });

    test('four equal tiles merge into two pairs', () {
      final result = slideLeft([2, 2, 2, 2]);
      expect(result.tiles, [4, 4, 0, 0]);
      expect(result.gainedScore, 8);
    });

    test('three equal tiles merge only the leftmost pair', () {
      final result = slideLeft([2, 2, 2, 0]);
      expect(result.tiles, [4, 2, 0, 0]);
      expect(result.gainedScore, 4);
    });

    test('a freshly merged tile does not merge again in the same slide', () {
      final result = slideLeft([4, 4, 8, 0]);
      expect(result.tiles, [8, 8, 0, 0]);
      expect(result.gainedScore, 8);
    });

    test('leaves an already-ordered non-mergeable row unchanged', () {
      final result = slideLeft([2, 4, 8, 16]);
      expect(result.tiles, [2, 4, 8, 16]);
      expect(result.gainedScore, 0);
    });

    test('an empty row stays empty', () {
      final result = slideLeft([0, 0, 0, 0]);
      expect(result.tiles, [0, 0, 0, 0]);
      expect(result.gainedScore, 0);
    });
  });

  group('applyMove', () {
    test('left slides and merges every row, summing the score', () {
      final result = applyMove([
        [2, 2, 0, 0],
        [0, 0, 4, 4],
        [0, 2, 0, 2],
        [8, 0, 0, 8],
      ], Direction.left);

      expect(result.board, [
        [4, 0, 0, 0],
        [8, 0, 0, 0],
        [4, 0, 0, 0],
        [16, 0, 0, 0],
      ]);
      expect(result.gainedScore, 32);
      expect(result.moved, isTrue);
    });

    test('right slides and merges every row toward the right edge', () {
      final result = applyMove([
        [2, 2, 0, 0],
        [4, 4, 0, 0],
        [0, 2, 0, 2],
        [2, 4, 8, 16],
      ], Direction.right);

      expect(result.board, [
        [0, 0, 0, 4],
        [0, 0, 0, 8],
        [0, 0, 0, 4],
        [2, 4, 8, 16],
      ]);
      expect(result.gainedScore, 16);
      expect(result.moved, isTrue);
    });

    test('up slides and merges every column toward the top', () {
      final result = applyMove([
        [2, 0, 0, 2],
        [2, 0, 4, 0],
        [0, 0, 4, 0],
        [0, 0, 0, 2],
      ], Direction.up);

      expect(result.board, [
        [4, 0, 8, 4],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(result.gainedScore, 16);
      expect(result.moved, isTrue);
    });

    test('down slides and merges every column toward the bottom', () {
      final result = applyMove([
        [2, 0, 0, 2],
        [2, 0, 4, 0],
        [0, 0, 4, 0],
        [0, 0, 0, 2],
      ], Direction.down);

      expect(result.board, [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [4, 0, 8, 4],
      ]);
      expect(result.gainedScore, 16);
      expect(result.moved, isTrue);
    });

    test('reports moved=false when nothing can slide or merge', () {
      final board = [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ];
      final result = applyMove(board, Direction.left);

      expect(result.board, board);
      expect(result.gainedScore, 0);
      expect(result.moved, isFalse);
    });

    test('does not mutate the input board', () {
      final board = [
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];
      applyMove(board, Direction.left);

      expect(board[0], [2, 2, 0, 0]);
    });
  });

  group('hasWon', () {
    test('is true when a 2048 tile is present', () {
      expect(
        hasWon([
          [2, 4, 8, 16],
          [0, 0, 0, 0],
          [0, 2048, 0, 0],
          [0, 0, 0, 0],
        ]),
        isTrue,
      );
    });

    test('is false when no tile has reached 2048', () {
      expect(
        hasWon([
          [2, 4, 8, 16],
          [32, 64, 128, 256],
          [512, 1024, 0, 0],
          [0, 0, 0, 0],
        ]),
        isFalse,
      );
    });
  });

  group('isGameOver', () {
    test('is false when at least one cell is empty', () {
      expect(
        isGameOver([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 0],
        ]),
        isFalse,
      );
    });

    test('is false when a merge is still possible despite a full board', () {
      expect(
        isGameOver([
          [2, 2, 4, 8],
          [4, 8, 16, 32],
          [2, 4, 8, 16],
          [4, 8, 16, 32],
        ]),
        isFalse,
      );
    });

    test('is true when the board is full and no moves remain', () {
      expect(
        isGameOver([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2],
        ]),
        isTrue,
      );
    });
  });

  group('emptyCells', () {
    test('returns the coordinates of every empty cell', () {
      final cells = emptyCells([
        [2, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 4],
      ]);

      // 14 empty cells; the two filled ones (0,0) and (3,3) are excluded.
      expect(cells.length, 14);
      expect(cells, isNot(contains((row: 0, col: 0))));
      expect(cells, isNot(contains((row: 3, col: 3))));
      expect(cells, contains((row: 0, col: 1)));
    });

    test('returns empty when the board is full', () {
      expect(
        emptyCells([
          [2, 4, 2, 4],
          [4, 2, 4, 2],
          [2, 4, 2, 4],
          [4, 2, 4, 2],
        ]),
        isEmpty,
      );
    });
  });

  group('placeTile', () {
    test('sets the value at the given cell without mutating the input', () {
      final board = [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];

      final result = placeTile(board, row: 1, col: 2, value: 4);

      expect(result[1][2], 4);
      expect(board[1][2], 0, reason: 'input must not be mutated');
    });
  });

  group('spawnRandomTile', () {
    test('adds exactly one tile of value 2 or 4 into an empty cell', () {
      final board = [
        [2, 4, 8, 16],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ];

      final result = spawnRandomTile(board, Random(42));

      final before = _countNonZero(board);
      final after = _countNonZero(result);
      expect(after, before + 1, reason: 'exactly one tile is added');

      final spawned = _newTileValue(board, result);
      expect(spawned == 2 || spawned == 4, isTrue);
    });

    test('returns the board unchanged when there are no empty cells', () {
      final full = [
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ];

      final result = spawnRandomTile(full, Random(1));
      expect(result, full);
    });
  });
}

int _countNonZero(List<List<int>> board) =>
    board.expand((row) => row).where((v) => v != 0).length;

/// Returns the value of the single cell that changed from empty to filled.
int _newTileValue(List<List<int>> before, List<List<int>> after) {
  for (var r = 0; r < before.length; r++) {
    for (var c = 0; c < before[r].length; c++) {
      if (before[r][c] == 0 && after[r][c] != 0) return after[r][c];
    }
  }
  throw StateError('no new tile found');
}
