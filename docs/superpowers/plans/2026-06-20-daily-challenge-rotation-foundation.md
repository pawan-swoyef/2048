# Daily Challenge Rotation — Foundation Plan (framework + 2048)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 2048-only Daily Challenge with a rotation framework (one game per day, looping) rendered under a unified "Hero Banner" daily chrome, with 2048 wired end-to-end and a safe fallback for games not yet added.

**Architecture:** A pure rotation module picks the day's game id. A `DailyGame` descriptor + `DailyPlayController` let the Daily screen embed any game's header-less board and receive its result. `DailyStore` is simplified to finished-results-only. The Daily screen owns the Hero Banner chrome and the shared result card. This plan registers only the 2048 descriptor; later plans add the other three games to the same registry.

**Tech Stack:** Flutter / Dart 3 (records), `shared_preferences`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-06-20-daily-challenge-rotation-design.md`. **Mockup:** `mockups/daily-challenge.html` (Direction A).

---

## File structure

- Create: `lib/game/daily/daily_rotation.dart` — pure rotation (id for a puzzle number).
- Create: `test/game/daily/daily_rotation_test.dart`.
- Modify: `lib/game/daily/daily_store.dart` — finished-results-only.
- Modify: `test/game/daily/daily_store_test.dart` — drop in-progress, score round-trip.
- Modify: `lib/game/daily/daily_share.dart` — game-agnostic share line.
- Modify: `test/game/daily/daily_share_test.dart` — new signature.
- Create: `lib/ui/daily/daily_play_controller.dart` — `DailyPlayController` (ChangeNotifier).
- Create: `test/ui/daily/daily_play_controller_test.dart`.
- Create: `lib/ui/daily/daily_game.dart` — `DailyGame` interface + `kDailyGames` registry.
- Create: `lib/ui/daily/games/game_2048_daily.dart` — `Game2048Daily` descriptor + 2048 play widget.
- Modify: `lib/ui/daily/daily_screen.dart` — rewritten Hero Banner chrome.
- Modify: `test/ui/daily/daily_screen_test.dart` — inject puzzle number, assert 2048 hero.

All tests run with `flutter test <path>`; full suite `flutter test`.

---

## Task 1: Rotation module

**Files:**
- Create: `lib/game/daily/daily_rotation.dart`
- Test: `test/game/daily/daily_rotation_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/game/daily/daily_rotation_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/daily/daily_rotation.dart';

void main() {
  test('rotation cycles through the games in order and loops', () {
    expect(dailyGameId(1), '2048');
    expect(dailyGameId(2), 'numbertap');
    expect(dailyGameId(3), 'numbersort');
    expect(dailyGameId(4), 'magicsquare');
    expect(dailyGameId(5), '2048'); // loops
    expect(dailyGameId(8), 'magicsquare');
  });

  test('dailyGameIndex is zero-based and wraps', () {
    expect(dailyGameIndex(1), 0);
    expect(dailyGameIndex(4), 3);
    expect(dailyGameIndex(5), 0);
  });

  test('rotation lists exactly the four games', () {
    expect(kDailyRotation, ['2048', 'numbertap', 'numbersort', 'magicsquare']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/daily/daily_rotation_test.dart`
Expected: FAIL — `Couldn't resolve the package ... daily_rotation.dart` / `dailyGameId` undefined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/game/daily/daily_rotation.dart`:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/daily/daily_rotation_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/game/daily/daily_rotation.dart test/game/daily/daily_rotation_test.dart
git commit -m "feat(daily): add game rotation module"
```

---

## Task 2: DailyStore — finished-results only

**Files:**
- Modify: `lib/game/daily/daily_store.dart`
- Test: `test/game/daily/daily_store_test.dart`

This drops in-progress storage/resume. `DailySaved` becomes `{success, score}`; a
non-null result means finished. `score` holds moves or deciseconds depending on
the day's game.

- [ ] **Step 1: Rewrite the test**

Replace the entire contents of `test/game/daily/daily_store_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/daily/daily_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('no saved result for today on a fresh install', () async {
    expect(await DailyStore().load(100), isNull);
  });

  test('records and loads a finished result for the day', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, score: 47);
    final saved = await s.load(100);
    expect(saved, isNotNull);
    expect(saved!.success, true);
    expect(saved.score, 47);
  });

  test('a result from a different day is not returned', () async {
    final s = DailyStore();
    await s.saveResult(99, success: true, score: 30);
    expect(await s.load(100), isNull);
  });

  test('the score round-trips for time-based games too', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, score: 124); // 12.4s as deciseconds
    expect((await s.load(100))!.score, 124);
  });

  test('daily streak increments on consecutive completions', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, score: 40);
    expect(await s.dailyStreak(), 1);
    await s.saveResult(101, success: true, score: 42);
    expect(await s.dailyStreak(), 2);
  });

  test('a DNF resets the daily streak', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, score: 40);
    await s.saveResult(101, success: false, score: 0);
    expect(await s.dailyStreak(), 0);
  });

  test('a missed day resets the streak to 1', () async {
    final s = DailyStore();
    await s.saveResult(100, success: true, score: 40);
    await s.saveResult(103, success: true, score: 50);
    expect(await s.dailyStreak(), 1);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/daily/daily_store_test.dart`
Expected: FAIL — `saveResult`'s named arg `score` isn't defined (still `moves`), and `DailySaved.score` undefined.

- [ ] **Step 3: Rewrite the implementation**

Replace the entire contents of `lib/game/daily/daily_store.dart` with:

```dart
import 'package:shared_preferences/shared_preferences.dart';

/// Today's finished daily-challenge result. A non-null instance means the day's
/// puzzle is done; there is no mid-run resume.
class DailySaved {
  final bool success;

  /// The day's score: moves for move-based games, deciseconds for timed ones.
  final int score;

  const DailySaved({required this.success, required this.score});
}

/// Persists the daily challenge: today's finished result and the
/// daily-completion streak. (No in-progress state — leaving restarts the day.)
class DailyStore {
  static const _resPuzzle = 'daily_res_puzzle';
  static const _resSuccess = 'daily_res_success';
  static const _resScore = 'daily_res_score';
  static const _streak = 'daily_streak';
  static const _lastPuzzle = 'daily_last_puzzle';

  /// Today's finished result for [todayPuzzle], or null if not finished.
  Future<DailySaved?> load(int todayPuzzle) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_resPuzzle) == todayPuzzle) {
      return DailySaved(
        success: prefs.getBool(_resSuccess) ?? false,
        score: prefs.getInt(_resScore) ?? 0,
      );
    }
    return null;
  }

  /// Records the finished result and updates the daily-completion streak.
  Future<void> saveResult(int puzzle,
      {required bool success, required int score}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_resPuzzle, puzzle);
    await prefs.setBool(_resSuccess, success);
    await prefs.setInt(_resScore, score);

    if (success) {
      final last = prefs.getInt(_lastPuzzle);
      final current = prefs.getInt(_streak) ?? 0;
      final next = last == puzzle
          ? current
          : last == puzzle - 1
              ? current + 1
              : 1;
      await prefs.setInt(_streak, next);
      await prefs.setInt(_lastPuzzle, puzzle);
    } else {
      await prefs.setInt(_streak, 0);
    }
  }

  Future<int> dailyStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streak) ?? 0;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/daily/daily_store_test.dart`
Expected: PASS (7 tests).

(The old `daily_screen.dart` will not compile against this yet — that is fixed in Task 6. Do not run the full suite until then.)

- [ ] **Step 5: Commit**

```bash
git add lib/game/daily/daily_store.dart test/game/daily/daily_store_test.dart
git commit -m "refactor(daily): store finished results only (no resume)"
```

---

## Task 3: Game-agnostic share line

**Files:**
- Modify: `lib/game/daily/daily_share.dart`
- Test: `test/game/daily/daily_share_test.dart`

- [ ] **Step 1: Rewrite the test**

Replace the entire contents of `test/game/daily/daily_share_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/daily/daily_share.dart';

void main() {
  test('includes game title, puzzle number, result and streak', () {
    final text = dailyShareText(
      gameTitle: '2048',
      puzzleNumber: 128,
      result: '🎯512 in 47 moves',
      dailyStreak: 5,
    );
    expect(text, contains('2048 Daily #128'));
    expect(text, contains('512'));
    expect(text, contains('47'));
    expect(text, contains('🔥5'));
  });

  test('works for a time-based game', () {
    final text = dailyShareText(
      gameTitle: 'Magic Square',
      puzzleNumber: 4,
      result: '⏱️ 20.1s',
      dailyStreak: 8,
    );
    expect(text, contains('Magic Square Daily #4'));
    expect(text, contains('20.1s'));
  });

  test('appends the link on its own line when provided', () {
    final text = dailyShareText(
      gameTitle: '2048',
      puzzleNumber: 1,
      result: '🎯512 in 30 moves',
      dailyStreak: 1,
      link: 'https://example.com',
    );
    expect(text, contains('\nhttps://example.com'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/game/daily/daily_share_test.dart`
Expected: FAIL — `dailyShareText` has no `gameTitle`/`result` params.

- [ ] **Step 3: Rewrite the implementation**

Replace the entire contents of `lib/game/daily/daily_share.dart` with:

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/game/daily/daily_share_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/game/daily/daily_share.dart test/game/daily/daily_share_test.dart
git commit -m "refactor(daily): game-agnostic share text"
```

---

## Task 4: DailyPlayController

**Files:**
- Create: `lib/ui/daily/daily_play_controller.dart`
- Test: `test/ui/daily/daily_play_controller_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/ui/daily/daily_play_controller_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/ui/daily/daily_play_controller.dart';

void main() {
  test('update sets metric/started and notifies listeners', () {
    final c = DailyPlayController();
    var notes = 0;
    c.addListener(() => notes++);
    c.update(metric: 3, started: true);
    expect(c.metric, 3);
    expect(c.started, true);
    expect(notes, 1);
  });

  test('complete fires onComplete once with success and score', () {
    final c = DailyPlayController();
    final calls = <List<Object>>[];
    c.onComplete = (success, score) => calls.add([success, score]);
    c.complete(true, 42);
    c.complete(true, 99); // ignored — already completed
    expect(calls, [
      [true, 42]
    ]);
    expect(c.isCompleted, true);
    expect(c.metric, 42);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/daily/daily_play_controller_test.dart`
Expected: FAIL — `DailyPlayController` undefined.

- [ ] **Step 3: Write minimal implementation**

Create `lib/ui/daily/daily_play_controller.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Bridges a daily game's play surface and the Daily screen. The surface pushes
/// its live [metric] (moves or deciseconds) and calls [complete] once when the
/// game ends; the screen listens to drive the live header and the finish flow.
class DailyPlayController extends ChangeNotifier {
  int metric = 0;
  bool started = false;
  bool _completed = false;

  bool get isCompleted => _completed;

  /// Called once when the game ends, with whether it was a success and the
  /// final score. Set by the Daily screen.
  void Function(bool success, int score)? onComplete;

  /// Updates the live values and notifies listeners.
  void update({int? metric, bool? started}) {
    if (metric != null) this.metric = metric;
    if (started != null) this.started = started;
    notifyListeners();
  }

  /// Reports the final result. Idempotent — a second call is ignored.
  void complete(bool success, int score) {
    if (_completed) return;
    _completed = true;
    metric = score;
    onComplete?.call(success, score);
    notifyListeners();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/daily/daily_play_controller_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/daily/daily_play_controller.dart test/ui/daily/daily_play_controller_test.dart
git commit -m "feat(daily): add DailyPlayController"
```

---

## Task 5: DailyGame interface + 2048 descriptor + registry

**Files:**
- Create: `lib/ui/daily/daily_game.dart`
- Create: `lib/ui/daily/games/game_2048_daily.dart`
- Test: `test/ui/daily/games/game_2048_daily_test.dart`

The descriptor exposes everything the Daily screen needs to render the hero, the
board, and the result card for one game. `Game2048Daily` ports the current daily
board logic (DailyChallenge + swipe + AnimatedBoard) into a play widget.

- [ ] **Step 1: Write the failing test**

Create `test/ui/daily/games/game_2048_daily_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game2048/ui/animated_board.dart';
import 'package:game2048/ui/daily/daily_game.dart';
import 'package:game2048/ui/daily/daily_play_controller.dart';
import 'package:game2048/ui/theme_controller.dart';

void main() {
  test('2048 descriptor exposes its metadata', () {
    final g = kDailyGames['2048']!;
    expect(g.id, '2048');
    expect(g.title, '2048');
    expect(g.metricLabel, 'Moves');
    expect(g.goalChip, contains('512'));
    expect(g.formatMetric(8), '8');
  });

  test('2048 result formatting reflects success and failure', () {
    final g = kDailyGames['2048']!;
    final win = g.resultStat(true, 31);
    expect(win.value, '512');
    expect(win.sub, contains('31'));
    expect(g.resultHeadline(true), contains('🎉'));
    expect(g.resultHeadline(false).toLowerCase(), contains('out of moves'));
    expect(g.shareResult(false, 0).toLowerCase(), contains("didn't make it"));
  });

  testWidgets('2048 play renders an AnimatedBoard from the seed', (tester) async {
    final c = DailyPlayController();
    await tester.pumpWidget(MaterialApp(
      home: ThemeScope(
        controller: ThemeController(),
        child: Scaffold(body: kDailyGames['2048']!.buildPlay(20260101, c)),
      ),
    ));
    await tester.pump();
    expect(find.byType(AnimatedBoard), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/daily/games/game_2048_daily_test.dart`
Expected: FAIL — `daily_game.dart` unresolved / `kDailyGames` undefined.

- [ ] **Step 3a: Write the DailyGame interface + registry**

Create `lib/ui/daily/daily_game.dart`:

```dart
import 'package:flutter/material.dart';

import 'daily_play_controller.dart';
import 'games/game_2048_daily.dart';

/// The big result-card stat for a finished daily (label / value / optional sub).
typedef DailyResultStat = ({String label, String value, String? sub});

/// Describes one game in the daily rotation: its hero metadata, its seeded play
/// surface, and how to format its live metric and final result.
abstract class DailyGame {
  String get id; // matches a kDailyRotation entry
  String get title; // "2048"
  String get emoji; // hero deco glyph
  Color get accent; // hero gradient base
  String get goalText; // "Reach 512 in the fewest moves"
  String get goalChip; // short hero chip, e.g. "🎯 512"
  String get metricLabel; // "Moves" | "Time"

  /// Formats a metric/score value for display ("8" or "12.4s").
  String formatMetric(int value);

  /// The result-card headline, e.g. "Great job! 🎉" / "Out of moves".
  String resultHeadline(bool success);

  /// The result-card big stat for a finished game.
  DailyResultStat resultStat(bool success, int score);

  /// The share-line result fragment, e.g. "🎯512 in 31 moves".
  String shareResult(bool success, int score);

  /// Whether the result card should celebrate (crown + confetti).
  bool celebrateOn(bool success) => success;

  /// Builds the header-less play surface, seeded by [seed], reporting to
  /// [controller].
  Widget buildPlay(int seed, DailyPlayController controller);
}

/// All daily games, keyed by id. Games are added here as they are implemented;
/// the Daily screen falls back to '2048' for any id not yet present.
final Map<String, DailyGame> kDailyGames = {
  '2048': Game2048Daily(),
};
```

- [ ] **Step 3b: Write the 2048 descriptor + play widget**

Create `lib/ui/daily/games/game_2048_daily.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../game/board.dart';
import '../../../game/game_state.dart' show kBoardSize;
import '../../../game/daily/daily_challenge.dart';
import '../../animated_board.dart';
import '../../swipe.dart';
import '../daily_game.dart';
import '../daily_play_controller.dart';

const _target = 512;

/// 2048 as a daily game: a date-seeded board, race to reach 512 in the fewest
/// moves (the board can fill first — a loss). Metric is moves.
class Game2048Daily extends DailyGame {
  @override
  String get id => '2048';
  @override
  String get title => '2048';
  @override
  String get emoji => '🔢';
  @override
  Color get accent => const Color(0xFFFFC12E);
  @override
  String get goalText => 'Reach $_target in the fewest moves';
  @override
  String get goalChip => '🎯 $_target';
  @override
  String get metricLabel => 'Moves';

  @override
  String formatMetric(int value) => '$value';

  @override
  String resultHeadline(bool success) =>
      success ? 'Great job! 🎉' : 'Out of moves';

  @override
  DailyResultStat resultStat(bool success, int score) => (
        label: success ? 'You reached' : "You couldn't reach",
        value: '$_target',
        sub: 'in $score moves',
      );

  @override
  String shareResult(bool success, int score) =>
      success ? '🎯$_target in $score moves' : "🎯$_target  ❌ didn't make it";

  @override
  Widget buildPlay(int seed, DailyPlayController controller) =>
      _Game2048Play(seed: seed, controller: controller);
}

class _Game2048Play extends StatefulWidget {
  final int seed;
  final DailyPlayController controller;
  const _Game2048Play({required this.seed, required this.controller});

  @override
  State<_Game2048Play> createState() => _Game2048PlayState();
}

class _Game2048PlayState extends State<_Game2048Play> {
  late DailyChallenge _ch;
  List<TileMove> _moves = const [];
  Set<int> _popCells = const {};
  int _tick = 0;
  bool _busy = false;
  Offset _swipeAccum = Offset.zero;
  bool _swipeFired = false;

  @override
  void initState() {
    super.initState();
    _ch = DailyChallenge(seed: widget.seed, puzzleNumber: 0, target: _target);
    _popCells = _allCells(_ch.state.board);
  }

  Set<int> _allCells(List<List<int>> board) {
    final cells = <int>{};
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        if (board[r][c] != 0) cells.add(r * kBoardSize + c);
      }
    }
    return cells;
  }

  void _onSwipeStart() {
    _swipeAccum = Offset.zero;
    _swipeFired = false;
  }

  void _onSwipeUpdate(Offset delta) {
    if (_swipeFired) return;
    _swipeAccum += delta;
    final dir = swipeDirection(_swipeAccum);
    if (dir != null) {
      _swipeFired = true;
      _move(dir);
    }
  }

  void _move(Direction dir) {
    if (_busy || _ch.status != DailyStatus.playing) return;
    final previous = _ch.state.board;
    final before = _ch.moves;
    _ch.move(dir);
    if (_ch.moves == before) return; // no-op

    final moves = planMove(previous, dir);
    final preSpawn = applyMove(previous, dir).board;
    final pop = <int>{};
    for (final m in moves) {
      if (m.merged) pop.add(m.toRow * kBoardSize + m.toCol);
    }
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        if (preSpawn[r][c] == 0 && _ch.state.board[r][c] != 0) {
          pop.add(r * kBoardSize + c);
        }
      }
    }

    setState(() {
      _moves = moves;
      _popCells = pop;
      _tick++;
      _busy = true;
    });
    widget.controller.update(metric: _ch.moves, started: true);
    if (_ch.status != DailyStatus.playing) {
      widget.controller.complete(_ch.status == DailyStatus.won, _ch.moves);
    }
    Future.delayed(const Duration(milliseconds: 110), () {
      if (mounted) setState(() => _busy = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => _onSwipeStart(),
      onHorizontalDragUpdate: (d) => _onSwipeUpdate(Offset(d.delta.dx, 0)),
      onHorizontalDragEnd: (_) => _swipeFired = false,
      onVerticalDragStart: (_) => _onSwipeStart(),
      onVerticalDragUpdate: (d) => _onSwipeUpdate(Offset(0, d.delta.dy)),
      onVerticalDragEnd: (_) => _swipeFired = false,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedBoard(
          board: _ch.state.board,
          moves: _moves,
          popCells: _popCells,
          tick: _tick,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/daily/games/game_2048_daily_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/daily/daily_game.dart lib/ui/daily/games/game_2048_daily.dart test/ui/daily/games/game_2048_daily_test.dart
git commit -m "feat(daily): add DailyGame interface and 2048 descriptor"
```

---

## Task 6: New DailyScreen (Hero Banner chrome)

**Files:**
- Modify: `lib/ui/daily/daily_screen.dart` (full rewrite)
- Test: `test/ui/daily/daily_screen_test.dart`

The screen picks today's game via the rotation (falling back to 2048 for ids not
yet in `kDailyGames`), renders the Hero Banner + the descriptor's play surface,
and shows the shared result card on completion. A `puzzleOverride` makes tests
deterministic regardless of date.

- [ ] **Step 1: Rewrite the test**

Replace the entire contents of `test/ui/daily/daily_screen_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/ui/animated_board.dart';
import 'package:game2048/ui/daily/daily_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

Widget _wrap({int? puzzle}) => MaterialApp(
      home: ThemeScope(
        controller: ThemeController(),
        child: DailyScreen(puzzleOverride: puzzle),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('puzzle 1 shows the 2048 daily hero and board', (tester) async {
    await tester.pumpWidget(_wrap(puzzle: 1)); // puzzle 1 -> 2048
    await tester.pumpAndSettle();
    expect(find.text('DAILY #1'), findsOneWidget);
    expect(find.textContaining('2048'), findsWidgets);
    expect(find.textContaining('512'), findsWidgets); // goal chip / goal text
    expect(find.byType(AnimatedBoard), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a pre-saved result shows the result card on open',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'daily_res_puzzle': 1,
      'daily_res_success': true,
      'daily_res_score': 31,
    });
    await tester.pumpWidget(_wrap(puzzle: 1));
    await tester.pumpAndSettle();
    expect(find.text('Great job! 🎉'), findsOneWidget);
    expect(find.textContaining('31'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/daily/daily_screen_test.dart`
Expected: FAIL — `DailyScreen` has no `puzzleOverride`; old screen references removed `DailyStore.saveInProgress` etc. won't compile.

- [ ] **Step 3: Rewrite the implementation**

Replace the entire contents of `lib/ui/daily/daily_screen.dart` with:

```dart
import 'package:flutter/material.dart';

import '../../game/daily/daily_rotation.dart';
import '../../game/daily/daily_seed.dart';
import '../../game/daily/daily_share.dart';
import '../../game/daily/daily_store.dart';
import '../share_card.dart';
import '../theme_controller.dart';
import '../win_card.dart';
import 'daily_game.dart';
import 'daily_play_controller.dart';

/// The daily challenge: one game per day on rotation (2048 → Number Tap →
/// Number Sort → Magic Square → repeat), under a shared Hero Banner chrome.
/// One attempt per day; only the finished result + streak persist.
class DailyScreen extends StatefulWidget {
  /// Overrides today's puzzle number (for tests). Production uses the date.
  final int? puzzleOverride;

  const DailyScreen({super.key, this.puzzleOverride});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final DailyStore _store = DailyStore();
  final GlobalKey _shareKey = GlobalKey();
  late final DailyPlayController _controller;

  int _puzzle = 0;
  int _streak = 0;
  late DailyGame _game;
  DailySaved? _done;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller = DailyPlayController()..onComplete = _onComplete;
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DailyGame _gameFor(int puzzle) =>
      kDailyGames[dailyGameId(puzzle)] ?? kDailyGames['2048']!;

  Future<void> _load() async {
    final today = DateTime.now();
    _puzzle = widget.puzzleOverride ?? puzzleNumber(today);
    _game = _gameFor(_puzzle);
    _streak = await _store.dailyStreak();
    final saved = await _store.load(_puzzle);
    if (mounted) {
      setState(() {
        _done = saved;
        _loaded = true;
      });
    }
  }

  Future<void> _onComplete(bool success, int score) async {
    await _store.saveResult(_puzzle, success: success, score: score);
    final streak = await _store.dailyStreak();
    if (mounted) {
      setState(() {
        _done = DailySaved(success: success, score: score);
        _streak = streak;
      });
    }
  }

  void _share() {
    final d = _done;
    if (d == null) return;
    shareResultImage(
      boundaryKey: _shareKey,
      text: dailyShareText(
        gameTitle: _game.title,
        puzzleNumber: _puzzle,
        result: _game.shareResult(d.success, d.score),
        dailyStreak: _streak,
        link: kStoreLink,
      ),
    );
  }

  String get _countdown {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: !_loaded
              ? Center(child: CircularProgressIndicator(color: theme.onBackground))
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _header(theme),
                              const SizedBox(height: 14),
                              _hero(theme),
                              const SizedBox(height: 14),
                              _game.buildPlay(dailySeed(DateTime.now()), _controller),
                              const SizedBox(height: 12),
                              _foot(theme),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_done != null) _shareCard(),
                    if (_done != null) _resultOverlay(theme),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _header(GameTheme theme) {
    final c = theme.onBackground;
    return Row(
      children: [
        _circleButton(theme, Icons.arrow_back, () => Navigator.of(context).maybePop()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('DAILY #$_puzzle',
                style: TextStyle(
                    color: c, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.scoreBox,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.glassStroke, width: 1.2),
          ),
          child: Text('🔥 $_streak',
              style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _circleButton(GameTheme theme, IconData icon, VoidCallback onTap) {
    return Material(
      color: theme.scoreBox,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: theme.onBackground, size: 20),
        ),
      ),
    );
  }

  Widget _hero(GameTheme theme) {
    final base = _game.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [base, Color.lerp(base, Colors.black, 0.30)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: base.withValues(alpha: 0.35), blurRadius: 22)],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -6,
            top: -10,
            child: Text(_game.emoji,
                style: TextStyle(fontSize: 84, color: Colors.white.withValues(alpha: 0.18))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⭐ TODAY\'S CHALLENGE',
                  style: TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
              const SizedBox(height: 2),
              Text(_game.title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(_game.goalText,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _metricChip(_game.goalChip),
                  const SizedBox(width: 10),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => _metricChip(
                        '${_game.metricLabel} ${_game.formatMetric(_controller.metric)}'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
    );
  }

  Widget _foot(GameTheme theme) {
    return Text('Next puzzle in $_countdown',
        style: TextStyle(
            color: theme.onBackground.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w700));
  }

  Widget _shareCard() {
    final d = _done!;
    final stat = _game.resultStat(d.success, d.score);
    return OffscreenShareCard(
      boundaryKey: _shareKey,
      card: ShareCard(
        title: '${_game.title} Daily #$_puzzle',
        valueLabel: stat.label,
        value: stat.value,
        valueSub: stat.sub,
        badge: '🔥 $_streak day streak',
      ),
    );
  }

  Widget _resultOverlay(GameTheme theme) {
    final d = _done!;
    final stat = _game.resultStat(d.success, d.score);
    final next = _gameFor(_puzzle + 1);
    return WinCardOverlay(
      child: WinCard(
        celebrate: _game.celebrateOn(d.success),
        banner: d.success ? 'DAILY DONE' : null,
        headline: _game.resultHeadline(d.success),
        stat: WinStat(label: stat.label, value: stat.value, sub: stat.sub),
        badge: '🔥 $_streak day daily streak',
        primaryLabel: 'Share Result',
        primaryIcon: Icons.share,
        onPrimary: _share,
        footerLabel: 'Next daily (${next.title}) in',
        footerValue: _countdown,
        onClose: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/ui/daily/daily_screen_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/ui/daily/daily_screen.dart test/ui/daily/daily_screen_test.dart
git commit -m "feat(daily): Hero Banner chrome with rotating game"
```

---

## Task 7: Full-suite verification

- [ ] **Step 1: Analyzer**

Run: `flutter analyze`
Expected: No new issues from the daily files.

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: All tests pass. The old `daily_challenge_test.dart` and
`daily_seed_test.dart` are unaffected (their APIs are unchanged).

- [ ] **Step 3: Commit any fixups** (only if needed)

```bash
git add -A
git commit -m "chore(daily): analyzer/test fixups"
```

---

## Notes for the implementer

- **Records syntax** (`({String label, String value, String? sub})`, the
  `DailyResultStat` typedef) requires Dart 3, already used in this repo.
- `DailyChallenge.puzzleNumber` is only stored, never used in its logic, so the
  2048 play widget passes `0` — the seed is what determines the board.
- The rotation is live but only `'2048'` is registered; other days fall back to
  2048 until their descriptors are added (next plan). This is intentional — the
  app stays fully working at every step.
- Do **not** `git add -A` except in the explicit fixup step — the branch has
  unrelated WIP. Stage only the files each task lists.
- After this plan: a follow-up plan adds `NumberTapDaily`, `NumberSortDaily`,
  `MagicSquareDaily` by extracting each game's board into a shared
  `<Game>BoardView` (daily mode: no undo/hint/settings, no hub best-score writes,
  guide off) and registering each descriptor in `kDailyGames`.
```
