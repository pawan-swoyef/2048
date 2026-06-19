// Builds the Wordle-style share text for a daily challenge result. Pure.

/// e.g. `2048 Daily #128  🎯512 in 47 moves  🔥5` (+ optional link line).
String dailyShareText({
  required int puzzleNumber,
  required int target,
  required bool success,
  required int moves,
  required int dailyStreak,
  String? link,
}) {
  final head = success
      ? '2048 Daily #$puzzleNumber  🎯$target in $moves moves  🔥$dailyStreak'
      : "2048 Daily #$puzzleNumber  🎯$target  ❌ didn't make it  🔥$dailyStreak";
  return link == null ? head : '$head\n$link';
}
