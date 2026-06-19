// Pure date → daily-challenge identifiers. Everyone computes the same puzzle
// number and seed for the same local date, so the challenge needs no backend.

/// First daily puzzle is on this date (puzzle #1).
final DateTime _epoch = DateTime(2026, 1, 1);

/// The puzzle number for [today] — whole days since the epoch, starting at 1.
int puzzleNumber(DateTime today) {
  final d = DateTime(today.year, today.month, today.day);
  return d.difference(_epoch).inDays + 1;
}

/// A deterministic RNG seed derived from [today]'s date (time ignored).
int dailySeed(DateTime today) =>
    today.year * 10000 + today.month * 100 + today.day;
