import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/daily/daily_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('no saved result for today on a fresh install', () async {
    expect(await DailyStore().load(100), isNull);
  });

  test('records and loads a finished result for the day', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, score: 47);
    final saved = await s.load(100);
    expect(saved, isNotNull);
    expect(saved!.success, true);
    expect(saved.score, 47);
  });

  test('a result from a different day is not returned', () async {
    final s = DailyStore();
    await s.saveResult(99, success: true, score: 30);
    expect(await s.load(100), isNull);
  });

  test('the score round-trips for time-based games too', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, score: 124); // 12.4s as deciseconds
    expect((await s.load(100))!.score, 124);
  });

  test('daily streak increments on consecutive completions', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, score: 40);
    expect(await s.dailyStreak(), 1);
    await s.saveResult(101, success: true, score: 42);
    expect(await s.dailyStreak(), 2);
  });

  test('a DNF resets the daily streak', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, score: 40);
    await s.saveResult(101, success: false, score: 0);
    expect(await s.dailyStreak(), 0);
  });

  test('a missed day resets the streak to 1', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, score: 40);
    await s.saveResult(103, success: true, score: 50);
    expect(await s.dailyStreak(), 1);
  });
}
