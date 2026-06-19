import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/board.dart';
import 'package:game2048/game/daily/daily_challenge.dart';

void main() {
  test('same seed produces the same starting board', () {
    final a = DailyChallenge(seed: 42, puzzleNumber: 1);
    final b = DailyChallenge(seed: 42, puzzleNumber: 1);
    expect(a.state.board, b.state.board);
  });

  test('replaying the same moves yields the same board (resumable)', () {
    final a = DailyChallenge(seed: 42, puzzleNumber: 1);
    final b = DailyChallenge(seed: 42, puzzleNumber: 1);
    for (final d in [Direction.left, Direction.up, Direction.right]) {
      a.move(d);
      b.move(d);
    }
    expect(a.state.board, b.state.board);
    expect(a.moves, b.moves);
    expect(a.history, b.history);
  });

  test('counts only board-changing moves', () {
    final dc = DailyChallenge(seed: 3, puzzleNumber: 1);
    for (final d in Direction.values) {
      final before = dc.state.board.toString();
      dc.move(d);
      if (dc.state.board.toString() != before) {
        expect(dc.moves, 1);
        return;
      }
      expect(dc.moves, 0); // no-op didn't count
    }
  });

  test('completes (won) when a tile reaches the target', () {
    final dc = DailyChallenge(seed: 5, puzzleNumber: 1, target: 4);
    var guard = 0;
    while (dc.status == DailyStatus.playing && guard < 500) {
      for (final d in Direction.values) {
        final before = dc.moves;
        dc.move(d);
        if (dc.moves != before || dc.status != DailyStatus.playing) break;
      }
      guard++;
    }
    expect(dc.status, DailyStatus.won);
  });

  test('is a DNF (lost) when the game ends before the target', () {
    final dc = DailyChallenge(seed: 7, puzzleNumber: 1, target: 1 << 20);
    var guard = 0;
    while (dc.status == DailyStatus.playing && guard < 5000) {
      for (final d in Direction.values) {
        final before = dc.moves;
        dc.move(d);
        if (dc.moves != before) break;
      }
      guard++;
    }
    expect(dc.status, DailyStatus.lost);
    expect(dc.moves, greaterThan(0));
  });
}
