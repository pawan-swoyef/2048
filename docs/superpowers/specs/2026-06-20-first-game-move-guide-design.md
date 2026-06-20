# First-game move guide for Number Sort & Magic Square

## Goal

Help players who open **Number Sort** or **Magic Square** for the first time by
glowing the suggested next move, the same way **Number Tap** highlights the next
correct tile in green. The guide appears only during a player's very first game
of each puzzle, then never again.

## Behavior

- A per-game "guide seen" flag is persisted on the device.
- The guide is **active until the player completes that game once**. During the
  first-ever playthrough the suggested next move glows; the moment the player
  finishes their first game the flag is set and the glow never appears again.
- Restarting / "New puzzle" mid-first-game keeps the guide on, because the
  player has not yet completed a game.
- The guide renders only when `guideActive && !isComplete && suggestion != null`.
- No changes to scoring, ads, hints, themes, or any other screen.

## Persistence

Add `GuideStore` (SharedPreferences-backed, mirroring `UndoStore` / `HintStore`):

- `Future<bool> guideSeen(String gameId)` — defaults to `false`.
- `Future<void> markGuideSeen(String gameId)`.

Keys: `guide_seen_numbersort`, `guide_seen_magicsquare`.

Each screen loads the flag in `initState` into `_guideActive`, and calls
`markGuideSeen(gameId)` inside `_finish` on first completion.

## Next-move computation (pure game logic)

### Magic Square — `({int value, int cell})? suggestedPlacement()`

Return the first empty non-clue cell `c` whose `solution[c]` is still in the
tray, as `(value: solution[c], cell: c)`. The full solution is already known to
the game, so this is a direct lookup. Returns `null` when the board is solved or
no follow-the-guide move exists.

### Number Sort — `({int from, int to})? suggestedMove()`

Run a depth-first search (same shape as the existing `_solvable`) that returns
the **first move of a winning line** from the current board state, so the glow
always advances toward a solution rather than to a dead end. Returns `null` when
the board is already complete or unsolvable.

## Rendering (matches Number Tap's green glow)

Reuse Number Tap's green treatment: `_greenGrad`
(`[0xFF7BE86B, 0xFF34C759]`), the `0xFFB6FF6B` border, and the green glow shadow.

- **Magic Square**: green glow/border on the suggested tray chip and a green
  border on the target cell.
- **Number Sort**: green glow on the suggested source column's top token and a
  green border on the target column.

Attach test keys (e.g. `ms-guide-cell`, `ms-guide-tray`, `sort-guide-from`,
`sort-guide-to`) so widget tests can assert the glow is present on the first
game and absent once the guide is seen.

## Testing (TDD)

- **Game logic**
  - `MagicSquareGame.suggestedPlacement` on fixed boards: returns the correct
    value+cell, and `null` when complete.
  - `NumberSortGame.suggestedMove` on fixed boards: returns a move that advances
    toward a solution, and `null` when complete.
- **GuideStore**: default `false` → `markGuideSeen` → `true`, per game id.
- **Widget**
  - Glow present on the first game (guideSeen == false).
  - Glow absent when guideSeen == true.
  - Glow disappears after the first game is completed.

## Out of scope

- Number Tap behavior is unchanged.
- No instructional overlay / coach-mark (guide is glow-only).
- No changes to hint, undo, ad, or paywall flows.
