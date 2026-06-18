# Home Hub + Daily Challenge

**Date:** 2026-06-18
**App:** 2048 Blocks: Merge Puzzle (`com.number.twofoureight`)
**Goal:** Add a daily, shareable challenge (viral + daily-return hook), reached
from a new home hub that sets up the game collection.

## Scope

Two increments, each independently shippable.

**Increment 1 — Home Hub**
- App opens to a hub listing games as themed cards (Classic 2048, Daily
  Challenge; Sudoku/others later).
- Relocate the engagement rollover (streak/gift/coins) to the hub so it runs on
  app open regardless of game.
- Per-game best scores.

**Increment 2 — Daily Challenge**
- A date-seeded 2048 challenge: reach the target tile in the fewest moves, one
  attempt per day, with a Wordle-style text share.

**Out of scope:** Sudoku/other games (drop into the registry later); image-card
sharing; leaderboards/backend. All local (SharedPreferences).

## Increment 1 — Home Hub

### Components
```
lib/ui/hub/game_registry.dart   # GameInfo descriptors + the kGames list
lib/ui/hub/hub_screen.dart       # themed grid of game cards + engagement row
```
- `GameInfo(id, title, subtitle, icon, accent, builder)`.
- `kGames = [classic2048, dailyChallenge]` (Sudoku appended later).
- `main.dart` `home:` → `HubScreen`.

### Engagement relocation
- The `applyDailyOpen` rollover + the streak/coin/gift stat row + the gift/streak
  dialogs move from `game_screen.dart` to `hub_screen.dart`.
- The 2048 screen keeps only its score header (drops the stat row).

### Per-game scores
- `ScoreStore` gains `bestFor(String gameId)` / `saveBest(String gameId, int)`.
- Migrate the existing `best_score` value to key `2048` on first run.
- Cards display each game's relevant best (2048 = high score; Daily = today's
  status).

## Increment 2 — Daily Challenge

### Daily seed (`lib/game/daily/daily_seed.dart`, pure)
- `int puzzleNumber(DateTime today)` = whole days since a fixed epoch
  (e.g. 2026-01-01), so every device computes the same number for the same
  local date.
- `int dailySeed(DateTime today)` = deterministic seed from the date.
- Everyone gets the **same board + RNG stream**; determinism holds because the
  engine routes all spawns through the injected `Random` (`Random(dailySeed)`).

### Challenge logic (`lib/game/daily/daily_challenge.dart`, pure)
- Wraps the existing 2048 `GameState` seeded with the daily seed.
- **Target tile: 512.** Counts each board-changing move.
- On a move, if a tile `>= target` first appears → **complete**, result =
  `moves`. If the board is `over` before reaching target → **DNF**.
- Result: `DailyResult { puzzleNumber, target, moves, success }`.

### One attempt per day
- The in-progress daily run is **persisted** (board, score, moves, started flag),
  so leaving and returning **resumes the same attempt** — no restart.
- Once the attempt ends (complete or DNF), the day is **locked**: reopening shows
  the result + share, not a new game.

### Store (`lib/game/daily/daily_store.dart`)
- `todayResult` / saved in-progress run (JSON in SharedPreferences).
- `dailyStreak` = consecutive days **completed** (separate from the app-open
  engagement streak), used in the share text.
- On completion: award coins (e.g. **+50**) once per day via the existing
  `ProgressStore`.

### Share (text/emoji, via `share_plus`)
- Example: `2048 Daily #128  🎯512 in 47 moves  🔥5`  + store link.
- DNF example: `2048 Daily #128  🎯512  ❌ didn't make it  🔥0`.
- Uses the system share sheet.

### UI
```
lib/ui/daily/daily_screen.dart        # board + move counter + target indicator
lib/ui/daily/daily_result_sheet.dart  # result + Share + countdown to tomorrow
```
- Hub card → daily screen. States: **not played** (start), **in progress**
  (resume), **done** (result + share + "Next in HHh MMm").
- Reuses `AnimatedBoard`, themes, dialog styling.

## Dependencies
- Add `share_plus` for the share sheet.

## Testing

- `daily_seed_test`: same date → same puzzle number & seed across calls;
  consecutive dates increment the puzzle number; date-only (ignores time).
- `daily_challenge_test`: deterministic board for a seed; move counting; target
  detection completes with correct move count; DNF on game over before target;
  attempt locks after completion.
- `daily_store_test`: save/resume in-progress run; today-result round-trip;
  daily streak increments on consecutive completions and resets on a missed day.
- `game_registry_test`: registry exposes the expected games.
- Widget tests: hub renders cards + engagement row; daily screen shows move
  counter; result sheet shows the share text and a Share button.

## Rollout
Additive; bump version for the release that includes it. Ship Increment 1, then
Increment 2.
