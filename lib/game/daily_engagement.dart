// Pure daily-engagement logic: streak rollover and gift claiming.
//
// No IO, no Flutter — dates are injected so the behaviour is fully testable.
// See docs/superpowers/specs/2026-06-08-engagement-pack-streak-gift-coins-design.md

import 'dart:math';

import 'reward_schedule.dart';

/// All locally-persisted engagement state. Immutable.
class PlayerProgress {
  final int coins;
  final int streakCurrent;
  final int streakLongest;

  /// Last local date (`yyyy-MM-dd`) counted toward the streak, or null if never.
  final String? lastActiveDate;

  /// Local date (`yyyy-MM-dd`) the daily gift was last claimed, or null.
  final String? giftClaimedDate;

  /// Streak freezes held (caps at 1).
  final int streakFreezes;

  const PlayerProgress({
    this.coins = 0,
    this.streakCurrent = 0,
    this.streakLongest = 0,
    this.lastActiveDate,
    this.giftClaimedDate,
    this.streakFreezes = 1,
  });

  PlayerProgress copyWith({
    int? coins,
    int? streakCurrent,
    int? streakLongest,
    String? lastActiveDate,
    String? giftClaimedDate,
    int? streakFreezes,
  }) {
    return PlayerProgress(
      coins: coins ?? this.coins,
      streakCurrent: streakCurrent ?? this.streakCurrent,
      streakLongest: streakLongest ?? this.streakLongest,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      giftClaimedDate: giftClaimedDate ?? this.giftClaimedDate,
      streakFreezes: streakFreezes ?? this.streakFreezes,
    );
  }
}

/// Outcome of a daily app-open rollover.
class DailyOpenResult {
  final PlayerProgress progress;
  final bool streakReset;
  final bool freezeUsed;

  const DailyOpenResult({
    required this.progress,
    required this.streakReset,
    required this.freezeUsed,
  });
}

/// `yyyy-MM-dd` key for a date.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parseKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Updates streak state for an app-open on [today]. Idempotent within a day.
DailyOpenResult applyDailyOpen(PlayerProgress prev, DateTime today) {
  final todayKey = dateKey(today);

  // First launch ever.
  if (prev.lastActiveDate == null) {
    return DailyOpenResult(
      progress: _refillFreeze(prev.copyWith(
        streakCurrent: 1,
        streakLongest: max(prev.streakLongest, 1),
        lastActiveDate: todayKey,
      )),
      streakReset: false,
      freezeUsed: false,
    );
  }

  final diff =
      DateTime(today.year, today.month, today.day).difference(_parseKey(prev.lastActiveDate!)).inDays;

  // Same day, or the clock moved backwards: no change.
  if (diff <= 0) {
    return DailyOpenResult(progress: prev, streakReset: false, freezeUsed: false);
  }

  // Consecutive day.
  if (diff == 1) {
    final streak = prev.streakCurrent + 1;
    return DailyOpenResult(
      progress: _refillFreeze(prev.copyWith(
        streakCurrent: streak,
        streakLongest: max(prev.streakLongest, streak),
        lastActiveDate: todayKey,
      )),
      streakReset: false,
      freezeUsed: false,
    );
  }

  // Missed exactly one day, and a freeze is available: save the streak.
  if (diff == 2 && prev.streakFreezes > 0) {
    final streak = prev.streakCurrent + 1;
    return DailyOpenResult(
      progress: _refillFreeze(prev.copyWith(
        streakCurrent: streak,
        streakLongest: max(prev.streakLongest, streak),
        streakFreezes: prev.streakFreezes - 1,
        lastActiveDate: todayKey,
      )),
      streakReset: false,
      freezeUsed: true,
    );
  }

  // Otherwise the streak resets.
  return DailyOpenResult(
    progress: prev.copyWith(
      streakCurrent: 1,
      streakLongest: max(prev.streakLongest, 1),
      lastActiveDate: todayKey,
    ),
    streakReset: true,
    freezeUsed: false,
  );
}

/// Grants a freeze (cap 1) when the streak completes a 7-day cycle.
PlayerProgress _refillFreeze(PlayerProgress p) {
  if (p.streakCurrent > 0 && p.streakCurrent % 7 == 0) {
    return p.copyWith(streakFreezes: 1);
  }
  return p;
}

/// Whether the daily gift can be claimed on [today].
bool giftAvailable(PlayerProgress p, DateTime today) =>
    p.giftClaimedDate != dateKey(today);

/// Claims the daily gift on [today], awarding gift + milestone coins. A no-op
/// if it was already claimed today.
PlayerProgress claimGift(PlayerProgress p, DateTime today) {
  if (!giftAvailable(p, today)) return p;
  final reward =
      giftCoins(giftDayFor(p.streakCurrent)) + milestoneBonus(p.streakCurrent);
  return p.copyWith(coins: p.coins + reward, giftClaimedDate: dateKey(today));
}
