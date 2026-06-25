import 'package:flutter/material.dart';

import '../../../game/board.dart';
import '../../../game/game_state.dart' show kBoardSize;
import '../../../game/daily/daily_challenge.dart';
import '../../../game/save_store.dart';
import '../../../game/score_store.dart';
import '../../../game/sound_service.dart';
import '../../animated_board.dart';
import '../../dialogs.dart';
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
  Widget buildPlay(int seed, int puzzle, DailyPlayController controller) =>
      _Game2048Play(seed: seed, puzzle: puzzle, controller: controller);
}

class _Game2048Play extends StatefulWidget {
  final int seed;
  final int puzzle;
  final DailyPlayController controller;
  const _Game2048Play(
      {required this.seed, required this.puzzle, required this.controller});

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

  final SoundService _sound = SoundService();
  final ScoreStore _store = ScoreStore();
  final GameSaveStore _saveStore = GameSaveStore();

  // A single key holds the one in-progress daily; the saved puzzle number guards
  // against resuming yesterday's game once the day (and seed) has rolled over.
  static const _saveId = 'daily_2048';

  @override
  void initState() {
    super.initState();
    _ch = DailyChallenge(seed: widget.seed, puzzleNumber: 0, target: _target);
    _popCells = _allCells(_ch.state.board);
    _loadSound();
    _maybeResume();
  }

  /// Offers to continue today's daily if it was left mid-attempt. The board is
  /// rebuilt by replaying the saved move history against the same seed.
  Future<void> _maybeResume() async {
    final saved = await _saveStore.load(_saveId);
    if (saved == null || !mounted) return;
    if (saved['puzzle'] != widget.puzzle) return; // a save from a previous day
    final DailyChallenge restored;
    try {
      restored = DailyChallenge.fromJson(saved,
          seed: widget.seed, puzzleNumber: 0, target: _target);
    } catch (_) {
      await _saveStore.clear(_saveId);
      return;
    }
    if (restored.status != DailyStatus.playing || restored.moves == 0) {
      await _saveStore.clear(_saveId);
      return;
    }
    if (!mounted) return;
    final resume = await confirmResume(context);
    if (!mounted) return;
    if (resume) {
      setState(() {
        _ch = restored;
        _moves = const [];
        _popCells = _allCells(_ch.state.board);
        _tick++;
      });
      widget.controller.update(metric: _ch.moves, started: true);
    } else {
      await _saveStore.clear(_saveId);
    }
  }

  Future<void> _loadSound() async {
    final on = await _store.loadSoundEnabled();
    _sound.enabled = on;
  }

  @override
  void dispose() {
    _sound.dispose();
    super.dispose();
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
    final hasMerge = moves.any((m) => m.merged);
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
      _saveStore.clear(_saveId);
      widget.controller.complete(_ch.status == DailyStatus.won, _ch.moves);
      _ch.status == DailyStatus.won ? _sound.win() : _sound.lose();
    } else {
      _saveStore.save(_saveId, {'puzzle': widget.puzzle, ..._ch.toJson()});
      if (hasMerge) {
        _sound.merge();
      } else {
        _sound.move();
      }
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
