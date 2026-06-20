# First-game move guide for Number Sort & Magic Square — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Glow the suggested next move for a player's very first game of Number Sort and Magic Square — the same kind of green highlight Number Tap uses — then never show it again.

**Architecture:** A small SharedPreferences-backed `GuideStore` persists a per-game "seen" flag. Each game's pure logic gains a `suggested…()` method that returns the next move to highlight. Each screen loads the flag in `initState`, renders a green glow on the suggested source + target while the guide is active, and marks the flag seen on first completion.

**Tech Stack:** Flutter / Dart 3 (records for return types), `shared_preferences`, `flutter_test`.

---

## File structure

- Create: `lib/game/guide_store.dart` — `GuideStore` (per-game "guide seen" flag). Shared by both games.
- Create: `test/game/guide_store_test.dart`
- Modify: `lib/game/magicsquare/magic_square_game.dart` — add `suggestedPlacement()`.
- Modify: `test/game/magicsquare/magic_square_game_test.dart`
- Modify: `lib/game/numbersort/number_sort_game.dart` — add `suggestedMove()`.
- Modify: `test/game/numbersort/number_sort_game_test.dart`
- Modify: `lib/ui/magicsquare/magic_square_screen.dart` — load flag, glow guide, mark seen.
- Modify: `test/ui/magicsquare/magic_square_screen_test.dart`
- Modify: `lib/ui/numbersort/number_sort_screen.dart` — load flag, glow guide, mark seen.
- Modify: `test/ui/numbersort/number_sort_screen_test.dart`

All tests run with: `flutter test <path>`. Full suite: `flutter test`.

---

## Task 1: GuideStore (persisted per-game "seen" flag)

**Files:**
- Create: `lib/game/guide_store.dart`
- Test: `test/game/guide_store_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/game/guide_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/guide_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a fresh install has not seen any guide', () async {
    final store = GuideStore();
    expect(await store.guideSeen('numbersort'), false);
    expect(await store.guideSeen('magicsquare'), false);
  });

  test('marking a guide seen persists for that game only', () async {
    final store = GuideStore();
    await store.markGuideSeen('numbersort');
    expect(await store.guideSeen('numbersort'), true);
    expect(await store.guideSeen('magicsquare'), false);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/guide_store_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'game2048' ... guide_store.dart` / `GuideStore` undefined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/game/guide_store.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the player has already seen the first-game move guide for a
/// given game id, so the guide shows only during their very first playthrough.
class GuideStore {
  static String _key(String gameId) => 'guide_seen_$gameId';

  /// Whether the guide for [gameId] has already been shown (defaults to false).
  Future<bool> guideSeen(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(gameId)) ?? false;
  }

  /// Records that the guide for [gameId] has been shown.
  Future<void> markGuideSeen(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(gameId), true);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/guide_store_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/game/guide_store.dart test/game/guide_store_test.dart
git commit -m "feat(guide): add GuideStore for first-game guide flag"
```

---

## Task 2: MagicSquareGame.suggestedPlacement()

**Files:**
- Modify: `lib/game/magicsquare/magic_square_game.dart` (add method after `hint()`, before `// --- generation helpers ---`)
- Test: `test/game/magicsquare/magic_square_game_test.dart` (add tests inside the existing `group('placement (fixed board)', ...)`)

- [ ] **Step 1: Write the failing test**

In `test/game/magicsquare/magic_square_game_test.dart`, add these tests inside the `group('placement (fixed board)', () { ... })` block (after the existing `'repeated hints solve the puzzle'` test, before the group's closing `});`). The group already defines `sol` and `make()`:

```dart
    test('suggestedPlacement points at an empty cell with its solution value',
        () {
      final g = make(); // clues 0..3; empty cells 4..8, tray 5,1,4,3,8
      final s = g.suggestedPlacement();
      expect(s, isNotNull);
      expect(g.grid[s!.cell], null);
      expect(g.clue[s.cell], false);
      expect(s.value, sol[s.cell]);
      expect(g.tray.contains(s.value), true);
    });

    test('suggestedPlacement returns null once the board is solved', () {
      final g = make();
      for (final c in [4, 5, 6, 7, 8]) {
        g.place(sol[c], c);
      }
      expect(g.isComplete, true);
      expect(g.suggestedPlacement(), null);
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/magicsquare/magic_square_game_test.dart`
Expected: FAIL — `The method 'suggestedPlacement' isn't defined for the type 'MagicSquareGame'`.

- [ ] **Step 3: Write minimal implementation**

In `lib/game/magicsquare/magic_square_game.dart`, add this method immediately after the `hint()` method (right before the `// --- generation helpers ---` comment):

```dart
  /// The next move to highlight for a first-time player: the first empty,
  /// non-clue cell whose correct value is still in the tray. Returns null when
  /// the board is solved or no tray-backed empty cell remains.
  ({int value, int cell})? suggestedPlacement() {
    for (var c = 0; c < 9; c++) {
      if (clue[c] || grid[c] != null) continue;
      final value = solution[c];
      if (tray.contains(value)) return (value: value, cell: c);
    }
    return null;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/magicsquare/magic_square_game_test.dart`
Expected: PASS (all existing tests + 2 new).

- [ ] **Step 5: Commit**

```bash
git add lib/game/magicsquare/magic_square_game.dart test/game/magicsquare/magic_square_game_test.dart
git commit -m "feat(magicsquare): add suggestedPlacement for first-game guide"
```

---

## Task 3: NumberSortGame.suggestedMove()

**Files:**
- Modify: `lib/game/numbersort/number_sort_game.dart` (add `suggestedMove()` + private `_solvePath` helper)
- Test: `test/game/numbersort/number_sort_game_test.dart`

`suggestedMove` returns the **first move of a shortest solution path** (found via breadth-first search). Shortest-path is important: it guarantees each suggested move strictly reduces the distance to a solution, so following the glow repeatedly always converges and never ping-pongs between two states (which a depth-first "any solution" search could).

- [ ] **Step 1: Write the failing test**

Add to the `main()` of `test/game/numbersort/number_sort_game_test.dart` (inside the existing `void main() { ... }`):

```dart
  test('suggestedMove returns a legal move that advances to a solution', () {
    // One move from solved: moving the lone 3 (col 3) onto col 2 finishes it.
    final g = NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3],
      [3],
    ]);
    final s = g.suggestedMove();
    expect(s, isNotNull);
    expect(g.canMove(s!.from, s.to), true);
    expect(g.move(s.from, s.to), true);
    expect(g.isComplete, true);
  });

  test('following suggestedMove repeatedly solves the board', () {
    final g = NumberSortGame.fromColumns([
      [1, 2, 1],
      [2, 3, 2],
      [3, 1, 3],
      [],
    ]);
    var guard = 0;
    while (!g.isComplete && guard++ < 50) {
      final s = g.suggestedMove();
      expect(s, isNotNull, reason: 'a solvable board always has a next move');
      expect(g.move(s!.from, s.to), true);
    }
    expect(g.isComplete, true);
  });

  test('suggestedMove returns null on a solved board', () {
    final g = NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3, 3],
      [],
    ]);
    expect(g.isComplete, true);
    expect(g.suggestedMove(), null);
  });
```

If `test/game/numbersort/number_sort_game_test.dart` does not already import the game, ensure this import is present at the top:

```dart
import 'package:game2048/game/numbersort/number_sort_game.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/numbersort/number_sort_game_test.dart`
Expected: FAIL — `The method 'suggestedMove' isn't defined for the type 'NumberSortGame'`.

- [ ] **Step 3: Write minimal implementation**

In `lib/game/numbersort/number_sort_game.dart`, add the public method right after `bool isComplete` getter (or anywhere among the public instance methods, e.g. after `undo()`):

```dart
  /// The next move to highlight for a first-time player: the first move of a
  /// shortest solution from the current board, so following the guide strictly
  /// progresses toward a win. Returns null when the board is solved or stuck.
  ({int from, int to})? suggestedMove() {
    final path = _solvePath([for (final c in columns) [...c]], height);
    if (path == null || path.isEmpty) return null;
    final first = path.first;
    return (from: first.from, to: first.to);
  }
```

Then add this private static helper next to the existing `_solvable` (e.g. directly below it):

```dart
  /// Breadth-first search returning a shortest list of moves that solves
  /// [start], or null if unsolvable. Shortest-path guarantees each first move
  /// reduces the distance to a solution, so guidance never cycles.
  static List<_Move>? _solvePath(List<List<int>> start, int height) {
    String key(List<List<int>> cols) =>
        (cols.map((c) => c.join(',')).toList()..sort()).join('|');

    if (_complete(start, height)) return [];
    final startKey = key(start);
    final queue = <List<List<int>>>[start];
    final parent = <String, ({String prev, _Move move})>{};
    final seen = <String>{startKey};
    var head = 0;
    while (head < queue.length) {
      final cur = queue[head++];
      for (var from = 0; from < cur.length; from++) {
        if (cur[from].isEmpty) continue;
        for (var to = 0; to < cur.length; to++) {
          if (to == from || cur[to].length >= height) continue;
          if (cur[to].isNotEmpty && cur[to].last != cur[from].last) continue;
          final next = [for (final c in cur) [...c]];
          next[to].add(next[from].removeLast());
          final nk = key(next);
          if (!seen.add(nk)) continue;
          parent[nk] = (prev: key(cur), move: _Move(from, to));
          if (_complete(next, height)) {
            final path = <_Move>[];
            var k = nk;
            while (k != startKey) {
              final p = parent[k]!;
              path.add(p.move);
              k = p.prev;
            }
            return path.reversed.toList();
          }
          queue.add(next);
        }
      }
    }
    return null;
  }
```

The first move of the returned path was expanded from `start` itself (its `prev`
is `startKey`), so its `from`/`to` indices are valid for the real `columns`.

(The existing private `_Move` class with `final int from; final int to;` is reused as-is.)

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/numbersort/number_sort_game_test.dart`
Expected: PASS (all existing tests + 3 new).

- [ ] **Step 5: Commit**

```bash
git add lib/game/numbersort/number_sort_game.dart test/game/numbersort/number_sort_game_test.dart
git commit -m "feat(numbersort): add suggestedMove for first-game guide"
```

---

## Task 4: Wire the guide into MagicSquareScreen

**Files:**
- Modify: `lib/ui/magicsquare/magic_square_screen.dart`
- Test: `test/ui/magicsquare/magic_square_screen_test.dart`

The suggested tray chip is wrapped in a keyed glow (`ms-guide-tray`); the suggested empty cell renders a keyed glow ring (`ms-guide-cell`). Both appear only while `_guideActive` and disappear once the guide is seen.

- [ ] **Step 1: Write the failing test**

Add to `test/ui/magicsquare/magic_square_screen_test.dart` (inside `main()`):

```dart
  testWidgets('first game glows the suggested move; seen game does not',
      (tester) async {
    _phoneSurface(tester);
    // Fresh install -> guide active.
    await tester.pumpWidget(_wrap(MagicSquareGame.fromSolution(_sol, {0, 1, 2, 3})));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ms-guide-tray')), findsOneWidget);
    expect(find.byKey(const Key('ms-guide-cell')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    // Guide already seen -> no glow.
    SharedPreferences.setMockInitialValues({'guide_seen_magicsquare': true});
    await tester.pumpWidget(_wrap(MagicSquareGame.fromSolution(_sol, {0, 1, 2, 3})));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ms-guide-tray')), findsNothing);
    expect(find.byKey(const Key('ms-guide-cell')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/magicsquare/magic_square_screen_test.dart`
Expected: FAIL — `Expected: exactly one matching candidate / Actual: _KeyWidgetFinder:<zero widgets with key [<'ms-guide-tray'>]>`.

- [ ] **Step 3: Write minimal implementation**

In `lib/ui/magicsquare/magic_square_screen.dart`:

a) Add the import near the other game imports:

```dart
import '../../game/guide_store.dart';
```

b) Add a guide-green constant near the existing color constants (top of file, after `_wrongOrange`):

```dart
const _guideGreen = Color(0xFFB6FF6B);
```

c) Add the store + state field to `_MagicSquareScreenState` (next to `_bestDeci` / `_allowance`):

```dart
  final GuideStore _guideStore = GuideStore();
  bool _guideActive = false;
```

d) In `initState`, after `_loadBest();`, add:

```dart
    _loadGuide();
```

e) Add the loader method (next to `_loadBest`):

```dart
  Future<void> _loadGuide() async {
    final seen = await _guideStore.guideSeen(_gameId);
    if (mounted) setState(() => _guideActive = !seen);
  }
```

f) In `_finish()`, after the best-time block (just before the method's closing `}`), add:

```dart
    if (_guideActive) {
      await _guideStore.markGuideSeen(_gameId);
      if (mounted) setState(() => _guideActive = false);
    }
```

g) In `build`, compute the guide and thread it into the board and tray. Replace the `_board(theme)` and `_tray(theme)` calls in the `Column(children: [...])` with passing `guide`:

Add near the top of `build`, after `final theme = ThemeScope.of(context);`:

```dart
    final guide = _guideActive && !_game.isComplete
        ? _game.suggestedPlacement()
        : null;
```

Change the two child calls from:

```dart
                        _board(theme),
                        const SizedBox(height: 14),
                        _tray(theme),
```

to:

```dart
                        _board(theme, guide),
                        const SizedBox(height: 14),
                        _tray(theme, guide),
```

h) Update `_board` to accept and forward the guide. Change its signature and the `_cell` call:

```dart
  Widget _board(GameTheme theme, ({int value, int cell})? guide) {
```

and in the row-building loop change `_cell(theme, r * 3 + col)` to:

```dart
                  Expanded(child: _cell(theme, r * 3 + col, guide)),
```

i) Update `_cell` to render a keyed glow ring when it is the guide target. Change its signature:

```dart
  Widget _cell(GameTheme theme, int index, ({int value, int cell})? guide) {
```

Inside `_cell`, compute `isGuide` after `final isClue = _game.clue[index];`:

```dart
    final isGuide = guide != null && guide.cell == index;
```

Then in the `builder`'s returned `Container`, change the `border` and `child` so the guide shows. Replace the existing `border:` line:

```dart
                border: Border.all(
                  color: active ? theme.win : theme.glassStroke,
                  width: active ? 2.6 : 1.2,
                ),
```

with:

```dart
                border: Border.all(
                  color: isGuide
                      ? _guideGreen
                      : active
                          ? theme.win
                          : theme.glassStroke,
                  width: (isGuide || active) ? 2.6 : 1.2,
                ),
```

and replace the existing `child:` line:

```dart
              child: value == null
                  ? null
                  : _numberTile(theme, value, isClue: isClue, cell: index),
```

with:

```dart
              child: value == null
                  ? (isGuide
                      ? const SizedBox.expand(key: Key('ms-guide-cell'))
                      : null)
                  : _numberTile(theme, value, isClue: isClue, cell: index),
```

j) Update `_tray` to accept the guide and forward it to `_trayChip`. Change signature:

```dart
  Widget _tray(GameTheme theme, ({int value, int cell})? guide) {
```

and change the chip-building loop `_trayChip(theme, value)` to:

```dart
                    for (final value in _game.tray) _trayChip(theme, value, guide),
```

k) Update `_trayChip` to wrap the suggested chip in a keyed glow. Change signature:

```dart
  Widget _trayChip(GameTheme theme, int value, ({int value, int cell})? guide) {
```

At the end of `_trayChip`, replace the final `return Draggable<_Drag>( ... );` block by capturing it and wrapping when guided. Concretely, change:

```dart
    return Draggable<_Drag>(
      key: Key('ms-tray-$value'),
      data: _Drag.fromTray(value),
      feedback: SizedBox(
          width: 54, height: 54, child: _tile(theme, value, dragging: true)),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
```

to:

```dart
    final draggable = Draggable<_Drag>(
      key: Key('ms-tray-$value'),
      data: _Drag.fromTray(value),
      feedback: SizedBox(
          width: 54, height: 54, child: _tile(theme, value, dragging: true)),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
    if (guide == null || guide.value != value) return draggable;
    return Container(
      key: const Key('ms-guide-tray'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _guideGreen, width: 2.5),
        boxShadow: [
          BoxShadow(color: _magicGreen.withValues(alpha: 0.7), blurRadius: 14),
        ],
      ),
      child: draggable,
    );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/magicsquare/magic_square_screen_test.dart`
Expected: PASS (all existing tests + the new one).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/magicsquare/magic_square_screen.dart test/ui/magicsquare/magic_square_screen_test.dart
git commit -m "feat(magicsquare): glow suggested move on first game"
```

---

## Task 5: Wire the guide into NumberSortScreen

**Files:**
- Modify: `lib/ui/numbersort/number_sort_screen.dart`
- Test: `test/ui/numbersort/number_sort_screen_test.dart`

The suggested source column's top token is wrapped in a keyed glow (`sort-guide-from`); the target column is wrapped in a keyed glow (`sort-guide-to`). Both appear only while `_guideActive`.

- [ ] **Step 1: Write the failing test**

Add to `test/ui/numbersort/number_sort_screen_test.dart` (inside `main()`):

```dart
  testWidgets('first game glows the suggested move; seen game does not',
      (tester) async {
    _phoneSurface(tester);
    final board = NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3],
      [3],
    ]);
    // Fresh install -> guide active.
    await tester.pumpWidget(_wrap(board));
    await tester.pump();

    expect(find.byKey(const Key('sort-guide-from')), findsOneWidget);
    expect(find.byKey(const Key('sort-guide-to')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    // Guide already seen -> no glow.
    SharedPreferences.setMockInitialValues({'guide_seen_numbersort': true});
    await tester.pumpWidget(_wrap(NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3],
      [3],
    ])));
    await tester.pump();

    expect(find.byKey(const Key('sort-guide-from')), findsNothing);
    expect(find.byKey(const Key('sort-guide-to')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/numbersort/number_sort_screen_test.dart`
Expected: FAIL — zero widgets with key `'sort-guide-from'`.

- [ ] **Step 3: Write minimal implementation**

In `lib/ui/numbersort/number_sort_screen.dart`:

a) Add the import near the other game imports:

```dart
import '../../game/guide_store.dart';
```

b) Add a guide-green constant after the existing `_gold` constant near the top:

```dart
const _guideGreen = Color(0xFFB6FF6B);
const _guideGlow = Color(0xFF34C759);
```

c) Add the store + state field to `_NumberSortScreenState` (next to `_bestMoves` / `_allowance`):

```dart
  final GuideStore _guideStore = GuideStore();
  bool _guideActive = false;
```

d) In `initState`, after `_loadBest();`, add:

```dart
    _loadGuide();
```

e) Add the loader method (next to `_loadBest`):

```dart
  Future<void> _loadGuide() async {
    final seen = await _guideStore.guideSeen(_gameId);
    if (mounted) setState(() => _guideActive = !seen);
  }
```

f) In `_finish()`, after the best-moves block (just before the method's closing `}`), add:

```dart
    if (_guideActive) {
      await _guideStore.markGuideSeen(_gameId);
      if (mounted) setState(() => _guideActive = false);
    }
```

g) In `build`, compute the guide and pass it to `_board`. After `final theme = ThemeScope.of(context);` add:

```dart
    final guide = _guideActive && !_game.isComplete
        ? _game.suggestedMove()
        : null;
```

Change the `_board(theme),` child call to:

```dart
                        _board(theme, guide),
```

h) Update `_board` to accept the guide and wrap the guided source token + target column. Change its signature:

```dart
  Widget _board(GameTheme theme, ({int from, int to})? guide) {
```

In the `LayoutBuilder` builder, replace the column-building loop:

```dart
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                _column(theme, i, colW, colH, tokenSize),
              ],
```

with one that threads `guide` into `_column`:

```dart
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                _column(theme, i, colW, colH, tokenSize, guide),
              ],
```

i) Update `_column` to glow when it is the guide target, and to forward the guide to its tokens. Change signature:

```dart
  Widget _column(GameTheme theme, int i, double w, double h, double tokenSize,
      ({int from, int to})? guide) {
```

Inside the `builder`, after `final col = _game.columns[i];`, add:

```dart
        final isGuideTo = guide != null && guide.to == i;
```

Change the column `Container`'s `border` to highlight the target:

```dart
            border: Border.all(
              color: isGuideTo
                  ? _guideGreen
                  : active
                      ? theme.win
                      : theme.glassStroke,
              width: (isGuideTo || active) ? 2.6 : 1.2,
            ),
```

Change the inner token loop to pass `guide` down to `_tokenAt`:

```dart
              for (var pos = col.length - 1; pos >= 0; pos--)
                _tokenAt(theme, i, pos, tokenSize, guide),
```

Finally, wrap the whole returned `Container` with a keyed marker when it is the target. Capture it into a local and return the wrapped version. Change the builder body so it ends with:

```dart
        final container = Container(
          key: Key('sort-col-$i'),
          width: w,
          height: h,
          // ... (unchanged padding/decoration/child) ...
        );
        if (!isGuideTo) return container;
        return KeyedSubtree(
          key: const Key('sort-guide-to'),
          child: container,
        );
```

(Keep the existing `Container(...)` contents exactly; only rename it to `final container = Container(...);` and add the `KeyedSubtree` wrap below it.)

j) Update `_tokenAt` to wrap the guided source column's top token in a keyed glow. Change signature:

```dart
  Widget _tokenAt(GameTheme theme, int colIndex, int pos, double size,
      ({int from, int to})? guide) {
```

The method currently returns `tile` for non-top tokens and a `Draggable` for the top token. Capture the top-token `Draggable` and wrap it when it is the guide source. Replace:

```dart
    return Draggable<int>(
      key: Key('sort-top-$colIndex'),
      data: colIndex,
      feedback: _tokenTile(theme, value, size, dragging: true),
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
      child: tile,
    );
```

with:

```dart
    final draggable = Draggable<int>(
      key: Key('sort-top-$colIndex'),
      data: colIndex,
      feedback: _tokenTile(theme, value, size, dragging: true),
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
      child: tile,
    );
    if (guide == null || guide.from != colIndex) return draggable;
    return Container(
      key: const Key('sort-guide-from'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _guideGreen, width: 2.5),
        boxShadow: [
          BoxShadow(color: _guideGlow.withValues(alpha: 0.7), blurRadius: 14),
        ],
      ),
      child: draggable,
    );
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/numbersort/number_sort_screen_test.dart`
Expected: PASS (all existing tests + the new one).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/numbersort/number_sort_screen.dart test/ui/numbersort/number_sort_screen_test.dart
git commit -m "feat(numbersort): glow suggested move on first game"
```

---

## Task 6: Full-suite verification

- [ ] **Step 1: Run the analyzer**

Run: `flutter analyze`
Expected: No new issues introduced by these files.

- [ ] **Step 2: Run the whole test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 3: Commit any fixups** (only if analyzer/tests required changes)

```bash
git add -A
git commit -m "chore(guide): fix analyzer/test feedback"
```

---

## Notes for the implementer

- **Records syntax** (`({int value, int cell})`) requires Dart 3; the codebase already uses Dart 3 features, so no pubspec change is needed.
- Access record fields with `.value` / `.cell` / `.from` / `.to`. Because the guide locals are nullable, guard with `guide != null` (done in every snippet above) — null-aware field access (`guide?.cell == index`) also works and is equivalent.
- The guide deactivates on the **first completed game** (`_finish`). Restart / "New" before finishing keeps it on by design.
- Number Tap is intentionally left unchanged.
```
