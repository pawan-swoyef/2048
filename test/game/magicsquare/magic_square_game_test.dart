import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/magicsquare/magic_square_game.dart';

// Independent re-derivation of the eight 3x3 magic squares (symmetries of the
// Lo Shu square), used to check the generator's uniqueness guarantee.
List<List<int>> _allMagicSquares() {
  List<int> rot(List<int> g) =>
      [g[6], g[3], g[0], g[7], g[4], g[1], g[8], g[5], g[2]];
  List<int> flip(List<int> g) =>
      [g[2], g[1], g[0], g[5], g[4], g[3], g[8], g[7], g[6]];
  var g = [2, 7, 6, 9, 5, 1, 4, 3, 8];
  final out = <String, List<int>>{};
  for (var i = 0; i < 4; i++) {
    out[g.join(',')] = g;
    final f = flip(g);
    out[f.join(',')] = f;
    g = rot(g);
  }
  return out.values.toList();
}

void main() {
  test('generated solution is a real magic square', () {
    final g = MagicSquareGame(Random(1));
    expect(g.solution.toSet(), {for (var i = 1; i <= 9; i++) i});
    for (final line in MagicSquareGame.lines) {
      expect(line.fold<int>(0, (s, c) => s + g.solution[c]), 15);
    }
  });

  test('does not start solved and has empty cells', () {
    final g = MagicSquareGame(Random(3));
    expect(g.isComplete, false);
    expect(g.grid.where((c) => c == null).isNotEmpty, true);
  });

  test('clues and tray together cover 1..9 exactly once', () {
    final g = MagicSquareGame(Random(5));
    final placed = [
      for (var i = 0; i < 9; i++)
        if (g.clue[i]) g.grid[i]!,
    ];
    final all = [...placed, ...g.tray]..sort();
    expect(all, [for (var i = 1; i <= 9; i++) i]);
  });

  test('the clue set pins down exactly one magic square', () {
    for (var seed = 0; seed < 40; seed++) {
      final g = MagicSquareGame(Random(seed));
      final clueCells = [for (var i = 0; i < 9; i++) if (g.clue[i]) i];
      final matches = _allMagicSquares().where((sq) {
        return clueCells.every((c) => sq[c] == g.solution[c]);
      }).length;
      expect(matches, 1, reason: 'seed $seed should be unique');
    }
  });

  group('placement (fixed board)', () {
    final sol = [2, 7, 6, 9, 5, 1, 4, 3, 8];
    // Clue cells 0..3 -> values 2,7,6,9. Empty cells 4..8, tray 5,1,4,3,8.
    MagicSquareGame make() => MagicSquareGame.fromSolution(sol, {0, 1, 2, 3});

    test('places a tray number into an empty cell and shrinks the tray', () {
      final g = make();
      expect(g.canPlace(5, 4), true);
      expect(g.place(5, 4), true);
      expect(g.grid[4], 5);
      expect(g.tray.contains(5), false);
    });

    test('cannot place onto a clue cell', () {
      final g = make();
      expect(g.canPlace(5, 0), false);
      expect(g.place(5, 0), false);
    });

    test('cannot place a number that is not in the tray', () {
      final g = make();
      expect(g.canPlace(2, 4), false); // 2 is a clue, not in tray
    });

    test('cannot place onto an already-filled cell', () {
      final g = make();
      g.place(5, 4);
      expect(g.canPlace(1, 4), false);
    });

    test('removing a placed number returns it to the tray', () {
      final g = make();
      g.place(5, 4);
      expect(g.removeAt(4), 5);
      expect(g.grid[4], null);
      expect(g.tray.contains(5), true);
    });

    test('a clue cell cannot be removed', () {
      final g = make();
      expect(g.removeAt(0), null);
      expect(g.grid[0], 2);
    });

    test('moving a placed number to an empty cell leaves the tray unchanged',
        () {
      final g = make();
      g.place(5, 4);
      final trayLen = g.tray.length;
      expect(g.move(4, 5), true);
      expect(g.grid[4], null);
      expect(g.grid[5], 5);
      expect(g.tray.length, trayLen);
    });

    test('lineIsMagic and isComplete reflect a solved board', () {
      final g = make();
      for (final c in [4, 5, 6, 7, 8]) {
        g.place(sol[c], c);
      }
      expect(g.lineIsMagic(MagicSquareGame.lines.first), true);
      expect(g.isComplete, true);
    });

    test('a wrong full board is not complete', () {
      final g = make();
      // Fill empties in the wrong order on purpose.
      final wrong = [8, 3, 4, 1, 5];
      final cells = [4, 5, 6, 7, 8];
      for (var i = 0; i < cells.length; i++) {
        g.place(wrong[i], cells[i]);
      }
      expect(g.grid.every((c) => c != null), true);
      expect(g.isComplete, false);
    });

    test('hint fills a correct empty cell and consumes it from the tray', () {
      final g = make();
      final cell = g.hint();
      expect(cell, isNotNull);
      expect(g.grid[cell!], sol[cell]);
      expect(g.tray.contains(sol[cell]), false);
    });

    test('repeated hints solve the puzzle', () {
      final g = make();
      while (!g.isComplete) {
        final c = g.hint();
        expect(c, isNotNull);
      }
      expect(g.isComplete, true);
    });

    test('suggestedPlacement points at an empty cell with its solution value',
        () {
      final g = make(); // clues 0..3; empty cells 4..8, tray 5,1,4,3,8
      final s = g.suggestedPlacement();
      expect(s, isNotNull);
      expect(g.grid[s!.cell], null);
      expect(g.clue[s.cell], false);
      expect(s.value, sol[s.cell]);
      expect(g.tray.contains(s.value), true);
    });

    test('suggestedPlacement returns null once the board is solved', () {
      final g = make();
      for (final c in [4, 5, 6, 7, 8]) {
        g.place(sol[c], c);
      }
      expect(g.isComplete, true);
      expect(g.suggestedPlacement(), null);
    });
  });
}
