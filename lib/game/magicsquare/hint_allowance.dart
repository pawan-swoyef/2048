// Pure logic for Magic Square's daily free-hint budget. Free players get one
// ad-hint per local day; premium players are unlimited. The midnight reset is
// "stored date differs from today". No IO here; persistence lives in HintStore.

class HintAllowance {
  /// Ad-hints a non-premium player gets each day.
  static const int dailyFree = 1;

  final bool premium;

  /// Ad-hints already used today (after the day-rollover reset is applied).
  final int used;

  const HintAllowance({required this.premium, required this.used});

  /// Reconstructs today's allowance from persisted values, resetting the count
  /// when [storedDate] is not [today].
  factory HintAllowance.forToday({
    required bool premium,
    required String storedDate,
    required int storedUsed,
    required String today,
  }) =>
      HintAllowance(
        premium: premium,
        used: storedDate == today ? storedUsed : 0,
      );

  bool get unlimited => premium;

  /// Ad-hints left today. Meaningful only for non-premium players.
  int get remaining =>
      premium ? dailyFree : (dailyFree - used).clamp(0, dailyFree);

  bool get canHint => premium || remaining > 0;
}
