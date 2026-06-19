# Number Sort — Design

**Date:** 2026-06-19
**Status:** Approved (pending written-spec review)

## Summary

A new game for the collection: **Number Sort**, a Water-Sort-style puzzle using
numbers instead of colors. The player drags the top token of a column onto
another column until every number is stacked together. Scored by **fewest
moves**. Undo is a monetized feature: free users get 3 undos/day, each behind a
rewarded ad; premium users get unlimited, ad-free undos.

The game slots into the existing architecture: pure logic in `lib/game/`, a
themed screen in `lib/ui/`, registered in the hub via `kGames`. It reuses the
existing premium flag, paywall, `ScoreStore`, themes, `WinCard`, and
`ShareCard`. The only genuinely new infrastructure is a rewarded-ad controller.

## 1. Gameplay rules

- **Board:** 4 columns. 3 columns start filled with a scramble of the numbers
  **1, 2, 3** (each number appears exactly 3 times → 9 tokens total). 1 column
  starts **empty** as workspace. Each column holds at most **3** tokens.
- **Move:** drag the **top** token of a column onto another column. A move is
  legal only if the target column's **top token is the same number**, or the
  target column is **empty**. Each completed drag counts as **1 move**.
- **Win:** every column is either empty or holds **3 of the same number**
  (i.e. each number's three tokens are stacked together).
- **Always solvable:** boards are generated so a solution always exists. The
  generator produces a random distribution and verifies solvability with a
  search-based solver, regenerating if the board is unsolvable or already
  solved. The board is tiny (9 tokens, 4 columns) so this is effectively
  instant.
- **Single fixed difficulty** for the MVP (3 numbers, height 3, 1 spare). The
  logic is parameterized (distinct-count, height, spare-count) so harder
  presets can be added later without a rewrite. Each new game reshuffles, so it
  is endlessly replayable at one difficulty.

## 2. Scoring

- **Metric: fewest moves.** The lowest move count to solve a board is saved as
  the player's best.
- Persisted via `ScoreStore.bestFor('numbersort')` / `saveBestFor`. A stored
  value of 0 means "no best yet".
- Hub card `bestLabel`: `Best: N moves`, or `Best: —` when none.

## 3. Undo, rewarded ads & IAP economy

- **Restart (free, unlimited):** reshuffles into a fresh solvable board and
  resets the move counter. The no-cost escape hatch; it forfeits all progress on
  the current board.
- **Undo (gated):** steps back the **last move**.
  - **Premium user** (owns `monthly` / `yearly` / `lifetime`, i.e. the existing
    premium flag is set): Undo works **instantly, unlimited, no ads**. No new
    purchase or product is introduced.
  - **Free user:** tapping Undo plays a **rewarded ad**; when the reward fires,
    one move is undone. Limited to **3 undos per day**. The button shows the
    remaining count (e.g. "Undo · 2 left").
  - **After 3/day used:** Undo is locked; tapping it opens the existing
    **paywall** ("Go unlimited").
  - Counter **resets at local midnight**, stored as `{date, usedCount}` in
    SharedPreferences.
- **Ad-load failure edge case:** if the rewarded ad fails to load, the undo is
  **granted anyway** (don't punish the user for a missing ad) and the daily
  counter **still increments**.

## 4. Architecture & files

Follows the established pattern: pure logic in `lib/game/`, screen in `lib/ui/`,
registered in the hub.

### New files

- **`lib/game/numbersort/number_sort_game.dart`** — pure Dart, no Flutter/IO.
  Board as `List<List<int>>` (columns, bottom→top), `moves` counter, internal
  undo stack of `(from, to)` moves. API: `canMove(from, to)`,
  `move(from, to)`, `undo()`, `isComplete`, and a solvable-board generator
  (random fill + search-based solvability check, regenerate if unsolvable or
  already solved). Constructor takes a `Random` for testability, plus optional
  config (distinct-count, height, spares) defaulting to 3/3/1.
- **`lib/game/numbersort/undo_allowance.dart`** — pure logic for the daily
  free-undo budget. Given today's date, the stored `{date, usedCount}`, and the
  premium flag, returns remaining undos and whether a reset is due. No IO, fully
  unit-testable.
- **`lib/game/numbersort/undo_store.dart`** — thin SharedPreferences wrapper
  persisting `{date, usedCount}` for the allowance.
- **`lib/ads/rewarded_ad.dart`** (+ `rewarded_ad_io.dart`,
  `rewarded_ad_stub.dart`) — `RewardedController` mirroring the interstitial
  conditional-export split. Real `google_mobile_ads` on Android/iOS; a no-op
  stub on web/desktop. API: `show(onReward)`. The stub fires `onReward`
  immediately so the game is testable without ads.
- **`lib/ui/numbersort/number_sort_screen.dart`** — themed screen. Column board
  with **drag-and-drop** (Flutter `Draggable` for the top token, `DragTarget`
  per column), move/best stat cards, Undo + Restart buttons, win overlay
  (`WinCard`) and share (`ShareCard`). Tile colors pulled from
  `GameTheme.tileColors(...)` so all 7 themes apply.

### Edited files

- **`lib/ui/hub/game_registry.dart`** — append a `GameInfo` for Number Sort
  (id `numbersort`, an appropriate icon/accent, and a `bestLabel` formatting
  moves).

### Reused as-is

`ScoreStore.bestFor/saveBestFor('numbersort')`, `ThemeScope`, `WinCard`,
`ShareCard`, the existing premium flag, and the paywall.

## 5. Testing

- **`test/game/numbersort/number_sort_game_test.dart`**
  - Move legality: legal onto matching top / empty column; illegal onto a
    different top or a full column.
  - Move counter increments only on a successful move.
  - `undo()` reverses exactly the last move and decrements the counter; undo
    with empty history is a no-op.
  - `isComplete` is true only when every column is empty or 3-of-a-kind.
  - Generator always produces a **solvable** board across many seeds and never
    starts already solved.
- **`test/game/numbersort/undo_allowance_test.dart`**
  - Fresh day → 3 undos; decrement to 0; the 4th is denied.
  - A new date → counter resets to 3.
  - Premium → always unlimited regardless of count.
- **Screen test** (light, mirroring `number_tap_screen_test.dart`): board
  renders, a drag performs a legal move, the win overlay appears on completion.
  Ad/IAP calls are stubbed; the no-op rewarded stub keeps this clean.

## Out of scope (YAGNI)

- Multiple/progressive difficulty levels (logic is parameterized to allow it
  later, but only one preset ships).
- Daily puzzle variant (a separate Daily Challenge game already exists).
- Level packs / hundreds of hand-authored levels (boards are procedurally
  generated).
- A dedicated "undo" IAP product — undo entitlement piggybacks on the existing
  premium flag.
