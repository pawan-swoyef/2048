// Pure date-rotation for the daily challenge: which game a given puzzle number
// plays. Same date → same game for everyone, no backend. The order matches the
// hub's kGames order.

/// The games the daily challenge rotates through, in order.
const List<String> kDailyRotation = [
  '2048',
  'numbertap',
  'numbersort',
  'magicsquare',
];

/// Zero-based index into [kDailyRotation] for [puzzleNumber] (1-based).
int dailyGameIndex(int puzzleNumber) =>
    (puzzleNumber - 1) % kDailyRotation.length;

/// The game id that [puzzleNumber] plays.
String dailyGameId(int puzzleNumber) => kDailyRotation[dailyGameIndex(puzzleNumber)];
