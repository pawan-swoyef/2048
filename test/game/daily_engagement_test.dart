import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/daily_engagement.dart';

void main() {
  // A fresh install: nothing recorded yet.
  const fresh = PlayerProgress();

  group('applyDailyOpen — streak', () {
    test('first ever open starts a 1-day streak', () {
      final r = applyDailyOpen(fresh, DateTime(2026, 6, 8));
      expect(r.progress.streakCurrent, 1);
      expect(r.progress.streakLongest, 1);
      expect(r.progress.lastActiveDate, '2026-06-08');
      expect(r.streakReset, false);
      expect(r.freezeUsed, false);
    });

    test('opening again the same day changes nothing', () {
      final day1 = applyDailyOpen(fresh, DateTime(2026, 6, 8)).progress;
      final r = applyDailyOpen(day1, DateTime(2026, 6, 8));
      expect(r.progress.streakCurrent, 1);
      expect(r.streakReset, false);
      expect(r.freezeUsed, false);
    });

    test('a consecutive day increments the streak', () {
      final day1 = applyDailyOpen(fresh, DateTime(2026, 6, 8)).progress;
      final r = applyDailyOpen(day1, DateTime(2026, 6, 9));
      expect(r.progress.streakCurrent, 2);
      expect(r.progress.streakLongest, 2);
    });

    test('missing exactly one day spends a freeze and keeps the streak', () {
      final prev = fresh.copyWith(
          streakCurrent: 4, streakLongest: 4, lastActiveDate: '2026-06-08', streakFreezes: 1);
      final r = applyDailyOpen(prev, DateTime(2026, 6, 10)); // skipped the 9th
      expect(r.freezeUsed, true);
      expect(r.streakReset, false);
      expect(r.progress.streakCurrent, 5);
      expect(r.progress.streakFreezes, 0);
    });

    test('missing one day with no freeze resets the streak', () {
      final prev = fresh.copyWith(
          streakCurrent: 4, lastActiveDate: '2026-06-08', streakFreezes: 0);
      final r = applyDailyOpen(prev, DateTime(2026, 6, 10));
      expect(r.streakReset, true);
      expect(r.progress.streakCurrent, 1);
    });

    test('missing more than one day resets even with a freeze', () {
      final prev = fresh.copyWith(
          streakCurrent: 9, lastActiveDate: '2026-06-08', streakFreezes: 1);
      final r = applyDailyOpen(prev, DateTime(2026, 6, 12)); // 3-day gap
      expect(r.streakReset, true);
      expect(r.progress.streakCurrent, 1);
      expect(r.progress.streakFreezes, 1); // freeze not spent on a reset
    });

    test('the device clock moving backwards is treated as the same day', () {
      final prev = fresh.copyWith(streakCurrent: 3, lastActiveDate: '2026-06-08');
      final r = applyDailyOpen(prev, DateTime(2026, 6, 7));
      expect(r.progress.streakCurrent, 3);
      expect(r.streakReset, false);
    });

    test('longest streak is preserved when the current streak resets', () {
      final prev = fresh.copyWith(
          streakCurrent: 9, streakLongest: 9, lastActiveDate: '2026-06-08', streakFreezes: 0);
      final r = applyDailyOpen(prev, DateTime(2026, 6, 12));
      expect(r.progress.streakCurrent, 1);
      expect(r.progress.streakLongest, 9);
    });

    test('reaching a 7-day cycle refills the streak freeze', () {
      final prev = fresh.copyWith(
          streakCurrent: 6, lastActiveDate: '2026-06-08', streakFreezes: 0);
      final r = applyDailyOpen(prev, DateTime(2026, 6, 9)); // -> streak 7
      expect(r.progress.streakCurrent, 7);
      expect(r.progress.streakFreezes, 1);
    });
  });

  group('gift', () {
    test('gift is available when not yet claimed today', () {
      final p = fresh.copyWith(giftClaimedDate: '2026-06-07');
      expect(giftAvailable(p, DateTime(2026, 6, 8)), true);
    });

    test('gift is not available once claimed today', () {
      final p = fresh.copyWith(giftClaimedDate: '2026-06-08');
      expect(giftAvailable(p, DateTime(2026, 6, 8)), false);
    });

    test('claiming pays the day-of-cycle coins and marks it claimed', () {
      final p = fresh.copyWith(streakCurrent: 5, coins: 100);
      final claimed = claimGift(p, DateTime(2026, 6, 8));
      expect(claimed.coins, 160); // 100 + day-5 gift (60)
      expect(claimed.giftClaimedDate, '2026-06-08');
    });

    test('claiming on a milestone day adds the milestone bonus too', () {
      final p = fresh.copyWith(streakCurrent: 7, coins: 0);
      final claimed = claimGift(p, DateTime(2026, 6, 8));
      expect(claimed.coins, 220); // day-7 gift (150) + 7-day milestone (70)
    });

    test('claiming again the same day is a no-op', () {
      final p = fresh.copyWith(streakCurrent: 5, coins: 100, giftClaimedDate: '2026-06-08');
      final claimed = claimGift(p, DateTime(2026, 6, 8));
      expect(claimed.coins, 100);
    });
  });
}
