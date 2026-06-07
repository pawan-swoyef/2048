/// Decides when a full-screen interstitial ad may be shown.
///
/// Pure logic so it's easy to test. Rules: never for premium users; only on
/// every [frequency]-th game over; and never more often than [minInterval].
class InterstitialPolicy {
  /// Show on every Nth game over.
  static const int frequency = 3;

  /// Minimum time between interstitials.
  static const Duration minInterval = Duration(minutes: 2);

  static bool shouldShow({
    required int gameOverCount,
    required DateTime? lastShown,
    required DateTime now,
    required bool premium,
  }) {
    if (premium) return false;
    if (gameOverCount <= 0) return false;
    if (gameOverCount % frequency != 0) return false;
    if (lastShown != null && now.difference(lastShown) < minInterval) {
      return false;
    }
    return true;
  }
}
