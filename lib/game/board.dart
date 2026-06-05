import 'dart:math';

/// A cell coordinate on the board.
typedef Cell = ({int row, int col});

/// Direction the player swipes to move all tiles.
enum Direction { left, right, up, down }

/// Result of applying a move to the whole board.
class MoveResult {
  /// The board after the move (a new 4x4 grid; the input is not mutated).
  final List<List<int>> board;

  /// Points gained from all merges in this move.
  final int gainedScore;

  /// Whether the move changed the board (false means it was a no-op).
  final bool moved;

  const MoveResult(this.board, this.gainedScore, this.moved);
}

/// Describes one tile's journey during a move: from its source cell to its
/// destination cell. [merged] is true when this tile combines with another at
/// the destination.
class TileMove {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final int value;
  final bool merged;

  const TileMove({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.value,
    required this.merged,
  });

  @override
  bool operator ==(Object other) =>
      other is TileMove &&
      other.fromRow == fromRow &&
      other.fromCol == fromCol &&
      other.toRow == toRow &&
      other.toCol == toCol &&
      other.value == value &&
      other.merged == merged;

  @override
  int get hashCode => Object.hash(fromRow, fromCol, toRow, toCol, value, merged);

  @override
  String toString() =>
      'TileMove(($fromRow,$fromCol)->($toRow,$toCol) v=$value merged=$merged)';
}

/// A single move within a row: source index [from], destination index [to].
typedef RowMove = ({int from, int to, bool merged});

/// Result of [slideLeftTracked]: the resulting tiles, score, and per-tile moves.
class RowSlide {
  final List<int> tiles;
  final int gainedScore;
  final List<RowMove> moves;

  const RowSlide(this.tiles, this.gainedScore, this.moves);
}

/// Result of sliding a single row to the left.
class RowResult {
  /// The row after sliding and merging, padded with zeros to the original length.
  final List<int> tiles;

  /// Points gained from merges in this slide (sum of each merged tile's value).
  final int gainedScore;

  const RowResult(this.tiles, this.gainedScore);
}

/// Slides a row to the left: compacts non-zero tiles, merges equal adjacent
/// pairs once each (left-to-right), then pads with zeros.
RowResult slideLeft(List<int> row) {
  final tracked = slideLeftTracked(row);
  return RowResult(tracked.tiles, tracked.gainedScore);
}

/// Like [slideLeft], but also records where each non-zero tile travels, so the
/// UI can animate the slide. [RowSlide.moves] lists, in source order, the
/// destination index of every non-zero tile and whether it merged.
RowSlide slideLeftTracked(List<int> row) {
  // Source indices and values of the non-zero tiles, in order.
  final sources = <({int index, int value})>[];
  for (var i = 0; i < row.length; i++) {
    if (row[i] != 0) sources.add((index: i, value: row[i]));
  }

  final merged = <int>[];
  final moves = <RowMove>[];
  var gainedScore = 0;

  var i = 0;
  while (i < sources.length) {
    final dest = merged.length;
    if (i + 1 < sources.length && sources[i].value == sources[i + 1].value) {
      final value = sources[i].value * 2;
      merged.add(value);
      gainedScore += value;
      moves.add((from: sources[i].index, to: dest, merged: true));
      moves.add((from: sources[i + 1].index, to: dest, merged: true));
      i += 2;
    } else {
      merged.add(sources[i].value);
      moves.add((from: sources[i].index, to: dest, merged: false));
      i += 1;
    }
  }

  while (merged.length < row.length) {
    merged.add(0);
  }

  return RowSlide(merged, gainedScore, moves);
}

/// Plans the per-tile movements for a move in [dir], mapping each non-zero
/// tile's source cell to its destination cell. Used to animate the slide.
List<TileMove> planMove(List<List<int>> board, Direction dir) {
  final tileMoves = <TileMove>[];

  for (final line in _linesFor(dir, board.length)) {
    final values = [for (final cell in line) board[cell.row][cell.col]];
    final slide = slideLeftTracked(values);
    for (final move in slide.moves) {
      final from = line[move.from];
      final to = line[move.to];
      tileMoves.add(TileMove(
        fromRow: from.row,
        fromCol: from.col,
        toRow: to.row,
        toCol: to.col,
        value: values[move.from],
        merged: move.merged,
      ));
    }
  }

  return tileMoves;
}

/// The cells of each line in slide order (starting from the edge tiles move
/// toward), so every direction reduces to a left-slide of [_linesFor].
List<List<Cell>> _linesFor(Direction dir, int n) {
  final lines = <List<Cell>>[];
  switch (dir) {
    case Direction.left:
      for (var r = 0; r < n; r++) {
        lines.add([for (var c = 0; c < n; c++) (row: r, col: c)]);
      }
    case Direction.right:
      for (var r = 0; r < n; r++) {
        lines.add([for (var c = n - 1; c >= 0; c--) (row: r, col: c)]);
      }
    case Direction.up:
      for (var c = 0; c < n; c++) {
        lines.add([for (var r = 0; r < n; r++) (row: r, col: c)]);
      }
    case Direction.down:
      for (var c = 0; c < n; c++) {
        lines.add([for (var r = n - 1; r >= 0; r--) (row: r, col: c)]);
      }
  }
  return lines;
}

/// Applies a move in [dir] to the whole [board].
///
/// Every direction reduces to [slideLeft]: rows are reversed for [Direction.right]
/// and the grid is transposed for vertical moves, then transformed back.
MoveResult applyMove(List<List<int>> board, Direction dir) {
  // Orient the grid so the move always becomes a left-slide of each row.
  List<List<int>> oriented;
  switch (dir) {
    case Direction.left:
      oriented = _copy(board);
      break;
    case Direction.right:
      oriented = _copy(board).map((r) => r.reversed.toList()).toList();
      break;
    case Direction.up:
      oriented = _transpose(board);
      break;
    case Direction.down:
      oriented = _transpose(board).map((r) => r.reversed.toList()).toList();
      break;
  }

  var gainedScore = 0;
  final slid = <List<int>>[];
  for (final row in oriented) {
    final result = slideLeft(row);
    slid.add(result.tiles);
    gainedScore += result.gainedScore;
  }

  // Reverse the orientation to restore the original axis.
  List<List<int>> resultBoard;
  switch (dir) {
    case Direction.left:
      resultBoard = slid;
      break;
    case Direction.right:
      resultBoard = slid.map((r) => r.reversed.toList()).toList();
      break;
    case Direction.up:
      resultBoard = _transpose(slid);
      break;
    case Direction.down:
      resultBoard = _transpose(slid.map((r) => r.reversed.toList()).toList());
      break;
  }

  final moved = !_equals(board, resultBoard);
  return MoveResult(resultBoard, gainedScore, moved);
}

/// Whether any tile has reached [target] (a win — defaults to 2048).
bool hasWon(List<List<int>> board, {int target = 2048}) {
  for (final row in board) {
    for (final value in row) {
      if (value >= target) return true;
    }
  }
  return false;
}

/// Whether the game is over: the board is full and no move changes it.
bool isGameOver(List<List<int>> board) {
  return !Direction.values.any((dir) => applyMove(board, dir).moved);
}

/// Coordinates of every empty (zero) cell on the board.
List<Cell> emptyCells(List<List<int>> board) {
  final cells = <Cell>[];
  for (var r = 0; r < board.length; r++) {
    for (var c = 0; c < board[r].length; c++) {
      if (board[r][c] == 0) cells.add((row: r, col: c));
    }
  }
  return cells;
}

/// Returns a new board with [value] placed at ([row], [col]). Input is not mutated.
List<List<int>> placeTile(
  List<List<int>> board, {
  required int row,
  required int col,
  required int value,
}) {
  final next = _copy(board);
  next[row][col] = value;
  return next;
}

/// Spawns a tile in a random empty cell: value 2 (90%) or 4 (10%).
///
/// Returns the board unchanged if there are no empty cells. [rng] is injected
/// so spawning is deterministic in tests.
List<List<int>> spawnRandomTile(List<List<int>> board, Random rng) {
  final cells = emptyCells(board);
  if (cells.isEmpty) return board;

  final cell = cells[rng.nextInt(cells.length)];
  final value = rng.nextInt(10) == 0 ? 4 : 2;
  return placeTile(board, row: cell.row, col: cell.col, value: value);
}

List<List<int>> _copy(List<List<int>> board) =>
    board.map((row) => List<int>.from(row)).toList();

List<List<int>> _transpose(List<List<int>> board) {
  final size = board.length;
  return List.generate(
    size,
    (r) => List.generate(size, (c) => board[c][r]),
  );
}

bool _equals(List<List<int>> a, List<List<int>> b) {
  for (var r = 0; r < a.length; r++) {
    for (var c = 0; c < a[r].length; c++) {
      if (a[r][c] != b[r][c]) return false;
    }
  }
  return true;
}
