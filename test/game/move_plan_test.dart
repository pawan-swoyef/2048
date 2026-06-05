import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/board.dart';

void main() {
  group('slideLeftTracked', () {
    test('produces the same tiles and score as slideLeft', () {
      final tracked = slideLeftTracked([2, 2, 4, 0]);
      expect(tracked.tiles, [4, 4, 0, 0]);
      expect(tracked.gainedScore, 4);
    });

    test('records the destination index of each non-zero tile', () {
      final tracked = slideLeftTracked([0, 2, 0, 2]);
      // Two 2s at indices 1 and 3 merge into destination index 0.
      expect(tracked.moves, [
        (from: 1, to: 0, merged: true),
        (from: 3, to: 0, merged: true),
      ]);
    });
  });

  group('planMove', () {
    List<List<int>> empty() =>
        List.generate(4, (_) => List<int>.filled(4, 0));

    test('a lone tile slides to the left wall without merging', () {
      final board = empty()..[0][3] = 2;
      final moves = planMove(board, Direction.left);

      expect(moves.length, 1);
      expect(moves.first,
          const TileMove(fromRow: 0, fromCol: 3, toRow: 0, toCol: 0, value: 2, merged: false));
    });

    test('two equal tiles slide to the same destination, marked merged', () {
      final board = empty()
        ..[0][0] = 2
        ..[0][1] = 2;
      final moves = planMove(board, Direction.left);

      expect(moves, containsAll(const [
        TileMove(fromRow: 0, fromCol: 0, toRow: 0, toCol: 0, value: 2, merged: true),
        TileMove(fromRow: 0, fromCol: 1, toRow: 0, toCol: 0, value: 2, merged: true),
      ]));
    });

    test('a tile already at the wall reports a zero-distance move', () {
      final board = empty()..[0][0] = 8;
      final moves = planMove(board, Direction.left);

      expect(moves.first,
          const TileMove(fromRow: 0, fromCol: 0, toRow: 0, toCol: 0, value: 8, merged: false));
    });

    test('right maps tiles to the right edge', () {
      final board = empty()
        ..[0][0] = 2
        ..[0][1] = 2;
      final moves = planMove(board, Direction.right);

      expect(moves, containsAll(const [
        TileMove(fromRow: 0, fromCol: 0, toRow: 0, toCol: 3, value: 2, merged: true),
        TileMove(fromRow: 0, fromCol: 1, toRow: 0, toCol: 3, value: 2, merged: true),
      ]));
    });

    test('up maps a column to the top', () {
      final board = empty()
        ..[0][0] = 2
        ..[1][0] = 2;
      final moves = planMove(board, Direction.up);

      expect(moves, containsAll(const [
        TileMove(fromRow: 0, fromCol: 0, toRow: 0, toCol: 0, value: 2, merged: true),
        TileMove(fromRow: 1, fromCol: 0, toRow: 0, toCol: 0, value: 2, merged: true),
      ]));
    });

    test('down maps a column to the bottom', () {
      final board = empty()
        ..[0][0] = 2
        ..[1][0] = 2;
      final moves = planMove(board, Direction.down);

      expect(moves, containsAll(const [
        TileMove(fromRow: 0, fromCol: 0, toRow: 3, toCol: 0, value: 2, merged: true),
        TileMove(fromRow: 1, fromCol: 0, toRow: 3, toCol: 0, value: 2, merged: true),
      ]));
    });

    test('emits exactly one move per non-zero tile', () {
      final board = [
        [2, 4, 8, 16],
        [0, 2, 0, 4],
        [0, 0, 0, 0],
        [2, 0, 2, 0],
      ];
      final nonZero = board.expand((r) => r).where((v) => v != 0).length;
      expect(planMove(board, Direction.left).length, nonZero);
    });
  });
}
