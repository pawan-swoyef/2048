import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/board.dart';
import 'package:game2048/game/daily/daily_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('no saved state for today on a fresh install', () async {
    expect(await DailyStore().load(100), isNull);
  });

  test('saves and resumes an in-progress run for today', () async {
    final s = DailyStore();
    await s.saveInProgress(100, 512, [Direction.left, Direction.up]);
    final saved = await s.load(100);
    expect(saved!.finished, false);
    expect(saved.history, [Direction.left, Direction.up]);
  });

  test('an in-progress run from a previous day is not returned', () async {
    final s = DailyStore();
    await s.saveInProgress(99, 512, [Direction.left]);
    expect(await s.load(100), isNull);
  });

  test('records a finished result for the day', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, moves: 47);
    final saved = await s.load(100);
    expect(saved!.finished, true);
    expect(saved.success, true);
    expect(saved.moves, 47);
  });

  test('daily streak increments on consecutive completions', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, moves: 40);
    expect(await s.dailyStreak(), 1);
    await s.saveResult(101, success: true, moves: 42);
    expect(await s.dailyStreak(), 2);
  });

  test('a DNF resets the daily streak', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, moves: 40);
    await s.saveResult(101, success: false, moves: 0);
    expect(await s.dailyStreak(), 0);
  });

  test('a missed day resets the streak to 1', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, moves: 40);
    await s.saveResult(103, success: true, moves: 50);
    expect(await s.dailyStreak(), 1);
  });
}
