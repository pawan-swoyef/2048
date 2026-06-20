# Daily Challenge — rotating games

## Goal

Turn the Daily Challenge from a 2048-only puzzle into a daily rotation through all
four games: day 1 is 2048, day 2 Number Tap, day 3 Number Sort, day 4 Magic
Square, then the loop repeats. Same date → same game and same seeded board for
everyone, no backend. The Daily screen uses one unified "Hero Banner" chrome
(Direction A from `mockups/daily-challenge.html`) around whichever game today is.

## Behavior

- The game for a given day is `kDailyRotation[(puzzleNumber - 1) % 4]`, over the
  registry order: `['2048', 'numbertap', 'numbersort', 'magicsquare']`.
- The day's board is built from `Random(dailySeed(today))`, so every player gets
  the identical puzzle. `puzzleNumber(today)` and `dailySeed(today)` are unchanged.
- **One attempt per day, finished-results only.** There is no mid-run resume:
  leaving and reopening restarts today's puzzle from the seed. Only the completed
  result and the streak persist. (This intentionally changes today's 2048 daily,
  which currently resumes mid-run.)
- Daily play is pure competition: the embedded board shows **no** undo / hint /
  settings buttons, does **not** write hub best-scores, and the first-game move
  guide is **off**.
- Success / metric per game:
  - 2048 — reach 512; metric = moves; **can fail** (board fills before 512).
  - Number Sort — solve; metric = moves; always succeeds once solved.
  - Number Tap — tap 1–25; metric = time (deciseconds); always succeeds.
  - Magic Square — all lines = 15; metric = time (deciseconds); always succeeds.
- Streak: a success extends the daily streak (consecutive puzzle numbers); a
  2048 loss resets it to 0. Unchanged from current logic.

## Architecture

Three layers, replacing the hardwired 2048 `DailyScreen`.

### 1. Rotation (pure) — `lib/game/daily/daily_rotation.dart`

```dart
const List<String> kDailyRotation = [
  '2048', 'numbertap', 'numbersort', 'magicsquare',
];

int dailyGameIndex(int puzzleNumber) =>
    (puzzleNumber - 1) % kDailyRotation.length;

String dailyGameId(int puzzleNumber) =>
    kDailyRotation[dailyGameIndex(puzzleNumber)];
```

No IO, no Flutter. `puzzleNumber` < 1 is never expected (epoch guards it), but
`(puzzleNumber - 1) % n` is only used with `puzzleNumber >= 1`.

### 2. Descriptor + play surface

`DailyPlayController` — a small `ChangeNotifier` the play surface talks to:

- `int metric` — the live score (moves or deciseconds); the surface updates it as
  play progresses so the hero banner can show it live.
- `bool started` — whether the run has begun (drives timer display, etc.).
- `void update({int? metric, bool? started})` — set + `notifyListeners()`.
- `void complete(bool success, int score)` — called once when the game ends; the
  DailyScreen subscribes to run its finish flow. Idempotent (ignores 2nd call).

`DailyGame` — a per-game descriptor:

```dart
abstract class DailyGame {
  String get id;             // matches a kDailyRotation entry
  String get title;          // "2048", "Number Tap", ...
  String get emoji;          // hero deco / ribbon glyph
  Color get accent;          // hero gradient base (reuse kGames accents)
  String get goalText;       // "Reach 512 in the fewest moves"
  String get metricLabel;    // "Moves" | "Time"
  String formatMetric(int v);// "8" | "12.4s"
  String resultValue();      // headline value, e.g. "512" (2048) — see below
  Widget buildPlay(int seed, DailyPlayController controller);
}
```

A registry `Map<String, DailyGame> kDailyGames` maps id → descriptor. Four
implementations: `Game2048Daily`, `NumberTapDaily`, `NumberSortDaily`,
`MagicSquareDaily`, each in `lib/ui/daily/games/`.

Each game gets a header-less, reusable **`<Game>BoardView`** widget rendering only
the board + interaction, seeded by `Random(seed)`, with a `daily` flag. To keep
rendering DRY, the board area is **extracted out of each hub screen** into this
widget; both the hub screen and the daily play surface render it.

- `daily: true` hides undo/hint/settings, suppresses hub best-score writes, and
  disables the first-game guide.
- 2048 already has `AnimatedBoard`; its play surface wraps `DailyChallenge` +
  swipe handling (largely the current `DailyScreen` board code, moved).
- Number Tap / Sort / Magic Square: extract `_grid`/`_board`/`_tray` (+ their
  cell/tile/token helpers) from the respective screens into the shared widget.

The play surface drives its descriptor's controller: pushes `metric` on each
move/tick and calls `complete(success, score)` when the game ends.

### 3. DailyScreen (Hero Banner) — `lib/ui/daily/daily_screen.dart` (rewritten)

1. `puzzle = puzzleNumber(today)`; `game = kDailyGames[dailyGameId(puzzle)]`.
2. Load saved result via `DailyStore.load(puzzle)`; load streak.
3. If finished → show the result card directly.
4. Else render the Hero Banner chrome: `‹  DAILY #N   🔥 streak`, the featured
   today's-game gradient card (emoji, title, `goalText`, live metric from the
   controller), then `game.buildPlay(dailySeed(today), controller)`.
5. On `controller.complete(success, score)` → `DailyStore.saveResult(puzzle,
   success, score)` → reload streak → show the shared result/share card with
   "Next daily (<next game title>) in <countdown>".

The result/share card stays the shared `WinCard` / `ShareCard`, fed by the
descriptor's `resultValue()` / `formatMetric` and the streak.

## Persistence — `lib/game/daily/daily_store.dart` (refactor)

Finished-results only. Remove in-progress storage and resume:

- Remove `saveInProgress`, the `_ip*` keys, and the history branch of `load`.
- `DailySaved` becomes `{ bool success, int score }` (drop `finished`/`history`;
  a non-null `DailySaved` means finished). Rename stored `_resMoves` → `_resScore`
  (it holds moves or deciseconds depending on the day's game).
- `load(puzzle)` returns the finished `DailySaved` for that puzzle, else null.
- `saveResult(puzzle, {success, score})` writes the result and updates streak /
  `lastPuzzle` exactly as today (success extends, failure resets).
- `dailyStreak()` unchanged.

`daily_share.dart` adjusts to take the game title + formatted metric instead of a
hardcoded "reached 512 in N moves" (so the share line fits any game).

## Error handling / edge cases

- Unknown id in `kDailyGames` is a programming error (the rotation and registry
  are both static and tested to agree); fail loud in tests, not at runtime.
- `complete` is idempotent so a double-fire (e.g. last move both reaches target
  and ends input) saves once.
- Theme changes apply globally as today (boards recolor with the active theme).

## Testing

- **Rotation** (`test/game/daily/daily_rotation_test.dart`): index cycles
  0,1,2,3,0,… for puzzle numbers 1..n; `dailyGameId` returns the registry order;
  `kDailyRotation` ids all exist in `kDailyGames`.
- **DailyStore** (`test/game/daily/daily_store_test.dart`, updated): result
  save/load with score round-trip; streak extends on consecutive success, resets
  on failure; no in-progress keys remain; `load` of a different puzzle is null.
- **Each `<Game>BoardView` in daily mode**: seeded board is deterministic for a
  fixed seed; completing fires `complete` with the right success + score; undo/
  hint/settings absent; guide off. Existing hub-mode screen tests still pass
  after the board extraction (regression guard).
- **DailyScreen** (`test/ui/daily/daily_screen_test.dart`): for an injected
  puzzle number it shows the correct game's hero + board; live metric updates;
  completing shows the result card; a pre-saved result shows the result card on
  open.

## Out of scope

- No mid-run resume (decided: finished-results only).
- No new games beyond the existing four.
- Hub `GameRegistry` "daily" card and `dailySeed`/`puzzleNumber` epoch unchanged.
- No backend / server sync (determinism is purely date-seeded).

## Implementation sequencing (for the plan)

1. Rotation module + tests.
2. `DailyStore` refactor (finished-results only) + tests.
3. `DailyPlayController` + `DailyGame` interface + `kDailyGames` skeleton.
4. 2048: `Game2048Daily` + move current board logic into it; new `DailyScreen`
   Hero Banner chrome wired end-to-end with 2048. (Proves the skeleton.)
5. Number Tap: extract `NumberTapBoardView`, add `NumberTapDaily`.
6. Number Sort: extract `NumberSortBoardView`, add `NumberSortDaily`.
7. Magic Square: extract `MagicSquareBoardView`, add `MagicSquareDaily`.
8. Share-text update + full-suite verification.
