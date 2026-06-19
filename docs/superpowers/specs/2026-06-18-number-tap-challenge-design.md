# Number Tap Challenge

**Date:** 2026-06-18
**App:** 2048 Blocks: Merge Puzzle → number-game collection
**Goal:** Add a fast speed/reflex game to the collection: tap 1–25 in order,
race the clock.

## Scope

- A new game: **Number Tap Challenge** — a 5×5 grid of shuffled numbers 1–25,
  tapped in ascending order, timed.
- Best-time persistence and display on the hub.
- Hub update: show **all** games (featured + compact cards), not just the
  featured one — so the new game (and later Daily Challenge / Sudoku) appears.

**Out of scope:** leaderboards/backend, daily-challenge integration of this game
(later). All local.

## Gameplay

- 5×5 grid, numbers 1–25 shuffled.
- Tap numbers in order. The timer starts on the **first tap**.
- **Correct** tap: the cell clears (dims/empties); `next` advances.
- **Wrong** tap: red flash + **+2s penalty**; a mistake is counted.
- Clearing all 25 ends the round. **Result time = elapsed seconds + 2 × mistakes.**
- **Best time** (lower is better) is saved and shown. "Play Again" reshuffles.

## Architecture

```
lib/game/numbertap/number_tap_game.dart   # pure logic (TDD)
lib/ui/numbertap/number_tap_screen.dart    # themed grid + timer + result overlay
```

### `number_tap_game.dart` (pure, no IO/Flutter)
- `NumberTapGame(Random rng)` — `board` = `[1..25]..shuffle(rng)` (cell → number).
- `int next` — next expected number (starts at 1).
- `int mistakes` — wrong taps.
- `void tap(int number)` — if `number == next`, `next++`; else `mistakes++`.
  No-op once complete.
- `bool get isComplete => next > 25`.
- `int get penaltySeconds => mistakes * 2`.
- `bool isCleared(int number) => number < next` — for dimming tapped cells.

### `number_tap_screen.dart`
- Themed 5×5 grid of number buttons (built from `board`).
- Header: live **timer** (mm:ss.t), the next number / progress, and mistakes.
- Timer: a `Stopwatch` started on the first tap; UI ticks via a periodic timer
  (cancelled on dispose / completion).
- Correct tap clears the cell; wrong tap flashes the tapped cell red.
- On completion: result overlay with final time + best, "Play Again".
- Reuses the current `GameTheme` (gradient background, themed tiles/buttons).

### Best time
- Stored via `ScoreStore` under id `numbertap`, value in **deciseconds**.
- On completion the screen min-checks: save only if no record or the new time is
  lower (`bestFor` returns 0 when unset).
- `GameInfo` gains an optional `String Function(int)? bestLabel` so the hub card
  formats `numbertap` as `Best: 23.4s` (and `0` → `Best: —`). Default games keep
  `Best: <n>`.

## Hub update

`HubScreen` currently renders only the featured (first) game. Change it to:
- Featured big card = `kGames.first` (2048), as today.
- **Below it, a compact card per remaining game** (icon + title + subtitle +
  best), tapping opens that game.
- Add `GameInfo` for `numbertap` (title "Number Tap", subtitle "Tap 1–25, beat
  the clock", a fitting icon/accent, `bestLabel` time formatter).

## Testing

- `number_tap_game_test`: board holds exactly 1–25; a correct tap advances
  `next`; a wrong tap increments `mistakes` and leaves `next`; tapping 1..25 in
  order completes; `penaltySeconds == 2 × mistakes`; taps after completion are
  no-ops.
- Widget tests (`number_tap_screen`): grid shows numbers 1–25; tapping the
  correct number clears/advances; tapping a wrong number counts a mistake;
  clearing all shows the result overlay.
- Hub widget test: a compact card for "Number Tap" renders.

## Rollout
Additive; bump version for the release that includes it.
