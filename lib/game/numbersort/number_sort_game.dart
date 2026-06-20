// Pure logic for Number Sort: a Water-Sort-style puzzle with numbers. Columns
// hold stacks of tokens (bottom -> top); the player moves the top token of one
// column onto another whose top matches or which is empty, until every column
// is either empty or a single repeated number. No IO, no Flutter.

import 'dart:math';

/// One recorded move, kept so it can be undone.
class _Move {
  final int from;
  final int to;
  const _Move(this.from, this.to);
}

class NumberSortGame {
  /// Distinct numbers in play (1..distinct).
  final int distinct;

  /// Maximum tokens a column can hold; also a solved column's size.
  final int height;

  /// Empty workspace columns. Total columns = distinct + spares.
  final int spares;

  /// Columns of tokens, each bottom -> top. Mutated as the player moves.
  final List<List<int>> columns;

  /// Completed moves so far (lower is better).
  int moves = 0;

  final List<_Move> _history = [];

  NumberSortGame._(this.distinct, this.height, this.spares, this.columns);

  /// Generates a fresh board that is guaranteed solvable and not already solved.
  factory NumberSortGame(Random rng,
      {int distinct = 3, int height = 3, int spares = 1}) {
    final tokens = [
      for (var n = 1; n <= distinct; n++) ...List.filled(height, n),
    ];
    while (true) {
      tokens.shuffle(rng);
      final columns = <List<int>>[
        for (var c = 0; c < distinct; c++)
          tokens.sublist(c * height, c * height + height),
        for (var s = 0; s < spares; s++) <int>[],
      ];
      if (_complete(columns, height)) continue;
      if (_solvable(columns, height)) {
        return NumberSortGame._(distinct, height, spares, columns);
      }
    }
  }

  /// Builds a game from explicit columns. For tests and fixed setups.
  factory NumberSortGame.fromColumns(List<List<int>> columns,
      {int height = 3}) {
    final cols = [for (final c in columns) [...c]];
    final filled = cols.where((c) => c.isNotEmpty).length;
    final spares = cols.length - filled;
    return NumberSortGame._(filled, height, spares, cols);
  }

  bool get canUndo => _history.isNotEmpty;

  bool get isComplete => _complete(columns, height);

  /// Whether the top token of [from] may be dropped on [to].
  bool canMove(int from, int to) {
    if (from == to) return false;
    final src = columns[from];
    if (src.isEmpty) return false;
    final dst = columns[to];
    if (dst.length >= height) return false;
    return dst.isEmpty || dst.last == src.last;
  }

  /// Moves the top token of [from] onto [to] if legal. Returns whether it ran.
  bool move(int from, int to) {
    if (!canMove(from, to)) return false;
    columns[to].add(columns[from].removeLast());
    _history.add(_Move(from, to));
    moves++;
    return true;
  }

  /// Reverses the most recent move. Returns whether anything was undone.
  bool undo() {
    if (_history.isEmpty) return false;
    final last = _history.removeLast();
    columns[last.from].add(columns[last.to].removeLast());
    moves--;
    return true;
  }

  /// The next move to highlight for a first-time player: the first move of a
  /// shortest solution from the current board, so following the guide strictly
  /// progresses toward a win. Returns null when the board is solved or stuck.
  ({int from, int to})? suggestedMove() {
    final path = _solvePath([for (final c in columns) [...c]], height);
    if (path == null || path.isEmpty) return null;
    final first = path.first;
    return (from: first.from, to: first.to);
  }

  static bool _complete(List<List<int>> cols, int height) => cols.every(
      (c) => c.isEmpty || (c.length == height && c.toSet().length == 1));

  /// Breadth-first search returning a shortest list of moves that solves
  /// [start], or null if unsolvable. Shortest-path guarantees each first move
  /// reduces the distance to a solution, so guidance never cycles.
  static List<_Move>? _solvePath(List<List<int>> start, int height) {
    String key(List<List<int>> cols) =>
        (cols.map((c) => c.join(',')).toList()..sort()).join('|');

    if (_complete(start, height)) return [];
    final startKey = key(start);
    final queue = <List<List<int>>>[start];
    final parent = <String, ({String prev, _Move move})>{};
    final seen = <String>{startKey};
    var head = 0;
    while (head < queue.length) {
      final cur = queue[head++];
      for (var from = 0; from < cur.length; from++) {
        if (cur[from].isEmpty) continue;
        for (var to = 0; to < cur.length; to++) {
          if (to == from || cur[to].length >= height) continue;
          if (cur[to].isNotEmpty && cur[to].last != cur[from].last) continue;
          final next = [for (final c in cur) [...c]];
          next[to].add(next[from].removeLast());
          final nk = key(next);
          if (!seen.add(nk)) continue;
          parent[nk] = (prev: key(cur), move: _Move(from, to));
          if (_complete(next, height)) {
            final path = <_Move>[];
            var k = nk;
            while (k != startKey) {
              final p = parent[k]!;
              path.add(p.move);
              k = p.prev;
            }
            return path.reversed.toList();
          }
          queue.add(next);
        }
      }
    }
    return null;
  }

  /// Depth-first search for any solution, used only at generation time.
  static bool _solvable(List<List<int>> start, int height) {
    String key(List<List<int>> cols) =>
        (cols.map((c) => c.join(',')).toList()..sort()).join('|');

    final seen = <String>{};
    bool dfs(List<List<int>> cols) {
      if (_complete(cols, height)) return true;
      if (!seen.add(key(cols))) return false;
      for (var from = 0; from < cols.length; from++) {
        if (cols[from].isEmpty) continue;
        for (var to = 0; to < cols.length; to++) {
          if (to == from || cols[to].length >= height) continue;
          if (cols[to].isNotEmpty && cols[to].last != cols[from].last) continue;
          final next = [for (final c in cols) [...c]];
          next[to].add(next[from].removeLast());
          if (dfs(next)) return true;
        }
      }
      return false;
    }

    return dfs([for (final c in start) [...c]]);
  }
}
