// Pure logic for Number Sort's daily free-undo budget. Free players get a fixed
// number of undos per local day; premium players are unlimited. The midnight
// reset is expressed as "stored date differs from today". No IO here so the
// rules stay testable; persistence lives in UndoStore.

class UndoAllowance {
  /// Free undos a non-premium player gets each day.
  static const int dailyFree = 3;

  final bool premium;

  /// Free undos already used today (after the day-rollover reset is applied).
  final int used;

  const UndoAllowance({required this.premium, required this.used});

  /// Reconstructs today's allowance from persisted values, resetting the count
  /// when [storedDate] is not [today].
  factory UndoAllowance.forToday({
    required bool premium,
    required String storedDate,
    required int storedUsed,
    required String today,
  }) =>
      UndoAllowance(
        premium: premium,
        used: storedDate == today ? storedUsed : 0,
      );

  bool get unlimited => premium;

  /// Free undos left today. Meaningful only for non-premium players.
  int get remaining =>
      premium ? dailyFree : (dailyFree - used).clamp(0, dailyFree);

  bool get canUndo => premium || remaining > 0;
}
