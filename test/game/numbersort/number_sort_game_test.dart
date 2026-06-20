import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/numbersort/number_sort_game.dart';

/// Solves the board with a depth-first search over states, used to assert that
/// generated boards are always solvable. Independent of the game's own logic.
bool _isSolvable(List<List<int>> start, int height) {
  String key(List<List<int>> cols) =>
      (cols.map((c) => c.join(',')).toList()..sort()).join('|');

  bool complete(List<List<int>> cols) => cols.every(
      (c) => c.isEmpty || (c.length == height && c.toSet().length == 1));

  final seen = <String>{};
  bool dfs(List<List<int>> cols) {
    if (complete(cols)) return true;
    final k = key(cols);
    if (!seen.add(k)) return false;
    for (var from = 0; from < cols.length; from++) {
      if (cols[from].isEmpty) continue;
      for (var to = 0; to < cols.length; to++) {
        if (to == from) continue;
        final dst = cols[to];
        if (dst.length >= height) continue;
        if (dst.isNotEmpty && dst.last != cols[from].last) continue;
        final next = [for (final c in cols) [...c]];
        next[to].add(next[from].removeLast());
        if (dfs(next)) return true;
      }
    }
    return false;
  }

  return dfs([for (final c in start) [...c]]);
}

void main() {
  test('starts with 4 columns: 3 filled, 1 empty workspace', () {
    final g = NumberSortGame(Random(1));
    expect(g.columns.length, 4);
    expect(g.columns.where((c) => c.isEmpty).length, 1);
    expect(g.columns.where((c) => c.length == 3).length, 3);
  });

  test('holds exactly three each of 1, 2, 3', () {
    final g = NumberSortGame(Random(1));
    final all = g.columns.expand((c) => c).toList();
    expect(all.length, 9);
    for (final n in [1, 2, 3]) {
      expect(all.where((x) => x == n).length, 3, reason: 'three of $n');
    }
  });

  test('does not start already solved', () {
    final g = NumberSortGame(Random(7));
    expect(g.isComplete, false);
  });

  test('every generated board is solvable across many seeds', () {
    for (var seed = 0; seed < 60; seed++) {
      final g = NumberSortGame(Random(seed));
      expect(_isSolvable(g.columns, g.height), true, reason: 'seed $seed');
    }
  });

  test('canMove allows a token onto an empty column', () {
    final g = NumberSortGame.fromColumns([
      [1, 2],
      [],
    ]);
    expect(g.canMove(0, 1), true);
  });

  test('canMove allows a token onto a matching top', () {
    final g = NumberSortGame.fromColumns([
      [1, 3],
      [2, 3],
    ]);
    expect(g.canMove(0, 1), true); // 3 onto 3
  });

  test('canMove rejects a token onto a different top', () {
    final g = NumberSortGame.fromColumns([
      [1, 3],
      [2, 1],
    ]);
    expect(g.canMove(0, 1), false); // 3 onto 1
  });

  test('canMove rejects moving from an empty column', () {
    final g = NumberSortGame.fromColumns([
      [],
      [1],
    ]);
    expect(g.canMove(0, 1), false);
  });

  test('canMove rejects a move onto a full column', () {
    final g = NumberSortGame.fromColumns([
      [1],
      [1, 1, 1],
    ], height: 3);
    expect(g.canMove(0, 1), false);
  });

  test('move transfers the top token and counts one move', () {
    final g = NumberSortGame.fromColumns([
      [1, 2],
      [],
    ]);
    expect(g.move(0, 1), true);
    expect(g.columns[0], [1]);
    expect(g.columns[1], [2]);
    expect(g.moves, 1);
  });

  test('an illegal move does nothing and is not counted', () {
    final g = NumberSortGame.fromColumns([
      [1, 3],
      [2, 1],
    ]);
    expect(g.move(0, 1), false);
    expect(g.columns[0], [1, 3]);
    expect(g.moves, 0);
  });

  test('undo reverses the last move and decrements the counter', () {
    final g = NumberSortGame.fromColumns([
      [1, 2],
      [],
    ]);
    g.move(0, 1);
    expect(g.undo(), true);
    expect(g.columns[0], [1, 2]);
    expect(g.columns[1], <int>[]);
    expect(g.moves, 0);
  });

  test('undo with no history is a no-op', () {
    final g = NumberSortGame.fromColumns([
      [1, 2],
      [],
    ]);
    expect(g.canUndo, false);
    expect(g.undo(), false);
    expect(g.moves, 0);
  });

  test('isComplete is true when each column is empty or 3-of-a-kind', () {
    final g = NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3, 3],
      [],
    ], height: 3);
    expect(g.isComplete, true);
  });

  test('isComplete is false when a column is mixed', () {
    final g = NumberSortGame.fromColumns([
      [1, 1, 2],
      [2, 2, 1],
      [3, 3, 3],
      [],
    ], height: 3);
    expect(g.isComplete, false);
  });

  test('suggestedMove returns a legal move that advances to a solution', () {
    // One move from solved: moving the lone 3 (col 3) onto col 2 finishes it.
    final g = NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3],
      [3],
    ]);
    final s = g.suggestedMove();
    expect(s, isNotNull);
    expect(g.canMove(s!.from, s.to), true);
    expect(g.move(s.from, s.to), true);
    expect(g.isComplete, true);
  });

  test('following suggestedMove repeatedly solves the board', () {
    final g = NumberSortGame.fromColumns([
      [1, 2, 1],
      [2, 3, 2],
      [3, 1, 3],
      [],
    ]);
    var guard = 0;
    while (!g.isComplete && guard++ < 50) {
      final s = g.suggestedMove();
      expect(s, isNotNull, reason: 'a solvable board always has a next move');
      expect(g.move(s!.from, s.to), true);
    }
    expect(g.isComplete, true);
  });

  test('suggestedMove returns null on a solved board', () {
    final g = NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3, 3],
      [],
    ]);
    expect(g.isComplete, true);
    expect(g.suggestedMove(), null);
  });
}
