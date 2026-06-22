import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/review_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final day = DateTime(2026, 6, 22);

  Future<void> winN(ReviewStore s, int n) async {
    for (var i = 0; i < n; i++) {
      await s.recordDailyWin();
    }
  }

  test('does not ask before the minimum number of wins', () async {
    final s = ReviewStore();
    await winN(s, ReviewStore.minWins - 1);
    expect(await s.shouldAsk(day), false);
  });

  test('asks once the minimum wins are reached', () async {
    final s = ReviewStore();
    await winN(s, ReviewStore.minWins);
    expect(await s.shouldAsk(day), true);
  });

  test('does not ask again within the cooldown window', () async {
    final s = ReviewStore();
    await winN(s, ReviewStore.minWins);
    await s.markAsked(day);
    expect(await s.shouldAsk(day), false);
    expect(
        await s.shouldAsk(day.add(const Duration(days: ReviewStore.cooldownDays - 1))),
        false);
  });

  test('asks again after the cooldown window passes', () async {
    final s = ReviewStore();
    await winN(s, ReviewStore.minWins);
    await s.markAsked(day);
    expect(
        await s.shouldAsk(day.add(const Duration(days: ReviewStore.cooldownDays))),
        true);
  });

  test('never asks again once rated', () async {
    final s = ReviewStore();
    await winN(s, ReviewStore.minWins + 5);
    await s.markRated();
    expect(await s.shouldAsk(day), false);
    expect(await s.shouldAsk(day.add(const Duration(days: 999))), false);
  });
}
