// Coin and milestone reward tables for the daily engagement loop.
//
// Pure data + functions — no IO, no Flutter. See the design spec at
// docs/superpowers/specs/2026-06-08-engagement-pack-streak-gift-coins-design.md

/// Coins paid by the daily gift for each day of the repeating 7-day cycle.
const Map<int, int> _giftCoinsByDay = {
  1: 10,
  2: 20,
  3: 30,
  4: 40,
  5: 60,
  6: 80,
  7: 150,
};

/// One-time bonus coins for reaching a streak milestone.
const Map<int, int> _milestoneBonus = {
  3: 30,
  7: 70,
  14: 150,
  30: 500,
};

/// Coins the daily gift pays for [day] (1–7) of the 7-day cycle.
int giftCoins(int day) => _giftCoinsByDay[day] ?? 0;

/// Bonus coins when the streak count [streak] lands exactly on a milestone,
/// otherwise 0.
int milestoneBonus(int streak) => _milestoneBonus[streak] ?? 0;

/// The position (1–7) of [streak] within the repeating 7-day gift cycle.
int giftDayFor(int streak) => ((streak - 1) % 7) + 1;
