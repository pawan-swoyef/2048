# Magic Square — Design

**Date:** 2026-06-19
**Status:** Approved (pending written-spec review)

## Summary

A new game for the collection: **Magic Square**, a 3×3 number puzzle. Some cells
start pre-filled as locked clues; the player drags the remaining numbers (1–9,
each used once) from a tray into the empty cells so that **every row, column, and
both diagonals sum to 15**. Scored by **best time**. A **Hint** reveals one
correct number and is monetized: a free player must choose between buying premium
or watching a rewarded ad (1 ad-hint per day); premium players get unlimited,
ad-free hints.

The game slots into the existing architecture: pure logic in `lib/game/`, a
themed screen in `lib/ui/`, one line in the hub registry. It reuses the
`RewardedController`, paywall, premium flag, `ScoreStore`, themes, `WinCard`,
and `ShareCard` already in the app.

## 1. Gameplay rules

- **Board:** a 3×3 grid. The hidden solution is a valid magic square using the
  numbers **1–9 exactly once**, where every row, every column, and **both
  diagonals** sum to **15**.
- **Start:** a few cells are pre-filled as **locked clues**. The remaining
  numbers sit in a **tray** below the grid. Single fixed difficulty for v1
  (~3–4 clues); the clue count is parameterized so easier/harder presets can be
  added later without a rewrite.
- **Placing:** **drag** a number from the tray into an empty cell. Drag a
  placed (non-clue) number back to the tray to remove it, or onto another empty
  cell to move it. Clue cells cannot be moved.
- **Live feedback:** each row, column, and both diagonals display their current
  sum, turning **green when the sum equals 15**.
- **Win:** all 9 cells are filled and every line sums to 15.
- **Always uniquely solvable:** the generator builds a full magic square, then
  selects a clue set that pins down **exactly one** valid completion. Uniqueness
  is verified against all 8 symmetries (rotations/reflections) of the 3×3 magic
  square — the only magic squares of 1–9 — so it is effectively instant. The
  board never starts already solved.
- **Score:** **best time** (fastest solve), persisted as the record. Reuses the
  Number Tap timer + share card.

## 2. Hint economy

- A **Hint** reveals one correct number into a currently-empty cell.
- **Premium player:** tapping Hint reveals a number **instantly — unlimited, no
  ads, no dialog**.
- **Free player:** tapping Hint first shows a **choice dialog** (never the ad
  directly):
  - **Go Premium** → opens the existing paywall (IAP).
  - **Watch Ad** → plays the rewarded ad, then reveals one number.
- The ad route is capped at **1 hint per day**. Once today's ad-hint is used,
  tapping Hint shows **only the Go-Premium option** (no more ads until tomorrow).
- The counter **resets at local midnight**, stored as `{date, usedCount}` in
  SharedPreferences.
- **Ad-load failure:** if the rewarded ad fails to load, the hint is granted
  anyway and the daily counter still increments (consistent with Number Sort).

## 3. Architecture & files

Follows the established pattern: pure logic in `lib/game/`, screen in `lib/ui/`,
registered in the hub.

### New files

- **`lib/game/magicsquare/magic_square_game.dart`** — pure Dart, no Flutter/IO.
  Holds the 3×3 grid as `List<int?>` (null = empty), a clue mask (locked cells),
  the hidden solution, and the tray (remaining numbers). API: `canPlace`,
  `place`, `removeAt`, `move`, `lineSum(line)`, `lineIsMagic(line)`,
  `isComplete`, `hint()` (fills one correct empty cell and consumes it from the
  tray), and a generator that guarantees a unique completion. Takes a `Random`
  for testability; clue count parameterized (default ~4).
- **`lib/game/magicsquare/hint_allowance.dart`** — pure logic for the daily
  hint budget: cap **1** for free players, unlimited for premium, with the
  midnight-reset rule. Mirrors `undo_allowance.dart`.
- **`lib/game/magicsquare/hint_store.dart`** — thin SharedPreferences wrapper
  persisting `{date, usedCount}` for the hint allowance.
- **`lib/ui/magicsquare/magic_square_screen.dart`** — themed screen: the 3×3
  grid with live line-sum labels, the number tray, drag-and-drop placement, a
  running timer, a Hint button, the win overlay (`WinCard`) and share
  (`ShareCard`). Colors come from `GameTheme` so all 7 themes apply.
- **`lib/ui/magicsquare/hint_choice_dialog.dart`** — the "Go Premium / Watch Ad"
  dialog shown to free players before any ad plays.

### Edited files

- **`lib/ui/hub/game_registry.dart`** — append a `GameInfo` for Magic Square
  (id `magicsquare`, icon/accent, and a `bestLabel` formatting the best time).

### Reused as-is

`RewardedController`, `PaywallScreen`, `ScoreStore.bestFor/saveBestFor('magicsquare')`
(lower time wins), `ThemeScope`/`GameTheme`, `WinCard`, `ShareCard`, the existing
premium flag.

The hint allowance/store mirror Number Sort's undo equivalents rather than
sharing a generic class — small, isolated duplication. Unifying them is deferred
until a third game needs the same mechanic (YAGNI).

## 4. Testing

- **`test/game/magicsquare/magic_square_game_test.dart`**
  - Generator produces a real magic square (every row/column/diagonal = 15;
    numbers 1–9 once).
  - Clues form a unique-completion set (no other of the 8 symmetries fits) and
    the board does not start solved.
  - Placement legality: cannot place on a clue cell; cannot place a number not in
    the tray; placing / removing / moving updates the tray correctly.
  - `lineSum` / `lineIsMagic` correct; `isComplete` true only when full **and**
    every line sums to 15.
  - `hint()` fills a currently-empty cell with its correct solution value and
    consumes it from the tray.
- **`test/game/magicsquare/hint_allowance_test.dart`**
  - Free → 1 hint/day; decrement to 0; the 2nd is denied.
  - A new date resets the count to 1.
  - Premium → unlimited regardless of count.
- **`test/game/magicsquare/hint_store_test.dart`**
  - Fresh install grants the daily hint; recording consumes it; new day resets;
    premium ignores the stored count.
- **Screen test** (light, mirroring the other screens): grid + tray render; a
  drag into the last empty cell of a near-solved injected board shows the win
  card; a free user sees the Hint **choice dialog**; a premium user's Hint
  reveals a number instantly. Ad/IAP calls are stubbed via the no-op rewarded
  stub.

## Out of scope (YAGNI)

- Multiple/progressive difficulty (logic is parameterized to allow it later, but
  one preset ships).
- 4×4 or larger magic squares.
- A daily Magic Square variant (a separate Daily Challenge game already exists).
- A dedicated hint IAP product — hint entitlement piggybacks on the existing
  premium flag.
- Unifying the hint and undo allowance/store into one generic class.
