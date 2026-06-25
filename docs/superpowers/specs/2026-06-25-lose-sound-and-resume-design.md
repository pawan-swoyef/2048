# Losing sound + mid-game resume — Design

Date: 2026-06-25
Status: Approved

## Goal

Two player-facing improvements:

1. **Losing sound** — a distinct "you lost" sound that replaces the current
   generic game-over sound at real loss moments.
2. **Mid-game resume** — if a player leaves a game mid-play (Home button, app
   closed, navigated away) and comes back, offer to continue the previous game
   instead of always starting fresh.

## Part 1 — Losing sound

The app already has a `SoundService` (`lib/game/sound_service.dart`) using
`audioplayers`, with `move/merge/win/gameOver/coin`. Files live in
`assets/sounds/*.wav`.

Changes:
- Register a new `lose` sound: add `'lose'` to `_names`, add `void lose() => _play('lose');`.
- Remove the now-unused `gameOver()` method (clean replace).
- Repoint the three real "you lost" call-sites from `gameOver()` → `lose()`:
  - 2048 board fills up (`lib/ui/game_screen.dart`).
  - Number Tap wrong tap (`lib/ui/numbertap/number_tap_screen.dart`).
  - Daily 2048 failure (`lib/ui/daily/games/game_2048_daily.dart`).
- Add an `assets/sounds/lose.wav` placeholder so the build/tests pass; the user
  overwrites it with the real sound.

`win`, `merge`, `move`, `coin` are unchanged.

## Part 2 — Mid-game resume

### Store

New `lib/game/save_store.dart` → `GameSaveStore`:
- `Future<void> save(String id, Map<String, dynamic> json)` — JSON-encodes and
  writes to SharedPreferences key `save_<id>`.
- `Future<Map<String, dynamic>?> load(String id)` — decodes, or null if absent/corrupt.
- `Future<void> clear(String id)` — removes the key.

Each game owns its own serialization; the store is a dumb JSON blob holder.

### Serialization

Add `toJson()` + `fromJson(Map)` to each game-state class:
- `GameState` (2048): board, score, best, won, keepGoing, over.
- `NumberTapGame`: grid/sequence, next target, mistakes, elapsed seconds.
- `NumberSortGame`: columns, moves, completion flags.
- `MagicSquareGame`: grid placement, elapsed seconds, hints used.
- Daily 2048 state.

Timer-based games serialize **elapsed seconds**, not a wall-clock start time, so
the clock effectively pauses while the player is away — keeping "best time" fair.

### Per-screen pattern (4 casual games)

1. `initState`: `load()` the save. If present, show a **"Continue previous
   game?" dialog (Resume / New Game)** on the first frame.
   - Resume → rebuild state from JSON, restart timer from saved elapsed.
   - New Game → `clear()`, start fresh.
2. After every move / state-changing `setState` → `save()`.
3. On win / lose / completion, or explicit restart → `clear()` (never resume a
   finished game).
4. `WidgetsBindingObserver`: on `AppLifecycleState.paused` → stop any running
   timer and persist. Prevents the timer inflating while backgrounded.

### Daily Challenge

Same in-progress save, keyed with the puzzle number/date so a stale save from a
previous day is ignored. The final result still goes to `DailyStore` only; the
in-progress save is separate and cleared on finish. Resume/New both stay within
the one-attempt-per-day rule — "New Game" just re-rolls the same *unfinished*
puzzle.

## Scope / decisions

- 5 screens + 5 state classes + 1 new store. No new packages (SharedPreferences
  + `dart:convert`).
- **Undo history is not persisted.** Resume restores the current board only; the
  undo stack resets. Undo-after-resume is a rare edge case.
- Round-trip unit tests for each `toJson`/`fromJson`.

## Verification

`flutter analyze`, run the test suite, and launch the app to confirm resume +
lose sound work end to end.
