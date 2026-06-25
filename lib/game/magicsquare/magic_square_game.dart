// Pure logic for Magic Square: a 3x3 grid where every row, column, and both
// diagonals must sum to 15 using the numbers 1..9 once each. Some cells start as
// locked clues; the player fills the rest from a tray. No IO, no Flutter.

import 'dart:math';

class MagicSquareGame {
  /// The target every line must sum to.
  static const int magicConstant = 15;

  /// The 8 lines that must each sum to [magicConstant]: 3 rows, 3 columns, 2
  /// diagonals (cell indices are row-major 0..8).
  static const List<List<int>> lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
    [0, 4, 8], [2, 4, 6], // diagonals
  ];

  /// The hidden solved board (1..9, row-major).
  final List<int> solution;

  /// Current board; null marks an empty cell.
  final List<int?> grid;

  /// Locked clue cells the player cannot change.
  final List<bool> clue;

  /// Numbers still available to place.
  final List<int> tray;

  MagicSquareGame._(this.solution, this.grid, this.clue, this.tray);

  /// Generates a board with [clues] locked cells whose completion is unique.
  factory MagicSquareGame(Random rng, {int clues = 4}) {
    final squares = _allMagicSquares();
    while (true) {
      final solution = squares[rng.nextInt(squares.length)];
      final cells = List.generate(9, (i) => i)..shuffle(rng);
      final clueCells = cells.take(clues).toSet();
      if (_uniqueCompletion(solution, clueCells, squares)) {
        final game = MagicSquareGame.fromSolution(solution, clueCells);
        game.tray.shuffle(rng);
        return game;
      }
    }
  }

  /// Builds a board from an explicit solution and clue cells. For tests and
  /// fixed setups.
  factory MagicSquareGame.fromSolution(List<int> solution, Set<int> clueCells) {
    final grid = List<int?>.generate(
        9, (i) => clueCells.contains(i) ? solution[i] : null);
    final clue = List<bool>.generate(9, (i) => clueCells.contains(i));
    final tray = [
      for (var i = 0; i < 9; i++)
        if (!clueCells.contains(i)) solution[i],
    ];
    return MagicSquareGame._(List.of(solution), grid, clue, tray);
  }

  /// Serializes the board for resume-on-return. The elapsed timer lives in the
  /// UI and is saved alongside this map.
  Map<String, dynamic> toJson() => {
        'solution': solution,
        'grid': grid,
        'clue': clue,
        'tray': tray,
      };

  /// Rebuilds a game from [toJson] output (decoded JSON).
  factory MagicSquareGame.fromJson(Map<String, dynamic> json) => MagicSquareGame._(
        [for (final v in json['solution'] as List) v as int],
        [for (final v in json['grid'] as List) v as int?],
        [for (final v in json['clue'] as List) v as bool],
        [for (final v in json['tray'] as List) v as int],
      );

  /// Whether [value] (from the tray) may be dropped on the empty, non-clue [cell].
  bool canPlace(int value, int cell) =>
      !clue[cell] && grid[cell] == null && tray.contains(value);

  /// Places [value] on [cell] if legal, consuming it from the tray.
  bool place(int value, int cell) {
    if (!canPlace(value, cell)) return false;
    grid[cell] = value;
    tray.remove(value);
    return true;
  }

  /// Clears a placed (non-clue) cell, returning its number to the tray. Returns
  /// the removed number, or null if the cell was empty or a clue.
  int? removeAt(int cell) {
    if (clue[cell] || grid[cell] == null) return null;
    final value = grid[cell]!;
    grid[cell] = null;
    tray.add(value);
    return value;
  }

  /// Moves a placed (non-clue) number from [from] to an empty (non-clue) [to].
  bool move(int from, int to) {
    if (clue[from] || clue[to]) return false;
    if (grid[from] == null || grid[to] != null) return false;
    grid[to] = grid[from];
    grid[from] = null;
    return true;
  }

  int lineSum(List<int> line) =>
      line.fold(0, (s, c) => s + (grid[c] ?? 0));

  bool lineComplete(List<int> line) => line.every((c) => grid[c] != null);

  bool lineIsMagic(List<int> line) =>
      lineComplete(line) && lineSum(line) == magicConstant;

  bool get isComplete =>
      grid.every((c) => c != null) && lines.every(lineIsMagic);

  /// Reveals one correct number: fills a not-yet-correct cell with its solution
  /// value, freeing that value from the tray or wherever it was misplaced.
  /// Returns the corrected cell, or null if the board is already solved.
  int? hint() {
    // Prefer an empty cell, then a wrongly filled one.
    var target = -1;
    for (var c = 0; c < 9; c++) {
      if (!clue[c] && grid[c] == null) {
        target = c;
        break;
      }
    }
    if (target == -1) {
      for (var c = 0; c < 9; c++) {
        if (!clue[c] && grid[c] != solution[c]) {
          target = c;
          break;
        }
      }
    }
    if (target == -1) return null;

    final value = solution[target];
    if (tray.contains(value)) {
      tray.remove(value);
    } else {
      final j = grid.indexOf(value); // misplaced in a non-clue cell
      if (j >= 0) grid[j] = null;
    }
    final old = grid[target];
    if (old != null) tray.add(old);
    grid[target] = value;
    return target;
  }

  /// The next move to highlight for a first-time player: the first empty,
  /// non-clue cell whose correct value is still in the tray. Returns null when
  /// the board is solved or no tray-backed empty cell remains.
  ({int value, int cell})? suggestedPlacement() {
    for (var c = 0; c < 9; c++) {
      if (clue[c] || grid[c] != null) continue;
      final value = solution[c];
      if (tray.contains(value)) return (value: value, cell: c);
    }
    return null;
  }

  // --- generation helpers -------------------------------------------------

  /// All eight 3x3 magic squares (the symmetries of the Lo Shu square).
  static List<List<int>> _allMagicSquares() {
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

  /// Whether [clueCells] are consistent with exactly one of [all] magic squares.
  static bool _uniqueCompletion(
      List<int> solution, Set<int> clueCells, List<List<int>> all) {
    var matches = 0;
    for (final sq in all) {
      if (clueCells.every((c) => sq[c] == solution[c])) matches++;
    }
    return matches == 1;
  }
}
