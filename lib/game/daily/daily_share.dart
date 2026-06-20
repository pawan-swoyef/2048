// Builds the Wordle-style share text for a daily challenge result. Pure and
// game-agnostic: the caller supplies the game title and a formatted result.

/// e.g. `2048 Daily #128  🎯512 in 47 moves  🔥5` (+ optional link line).
String dailyShareText({
  required String gameTitle,
  required int puzzleNumber,
  required String result,
  required int dailyStreak,
  String? link,
}) {
  final head = '$gameTitle Daily #$puzzleNumber  $result  🔥$dailyStreak';
  return link == null ? head : '$head\n$link';
}
