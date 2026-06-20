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
