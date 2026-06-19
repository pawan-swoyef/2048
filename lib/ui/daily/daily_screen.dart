import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../game/board.dart';
import '../../game/game_state.dart' show kBoardSize;
import '../../game/daily/daily_challenge.dart';
import '../../game/daily/daily_seed.dart';
import '../../game/daily/daily_share.dart';
import '../../game/daily/daily_store.dart';
import '../animated_board.dart';
import '../swipe.dart';
import '../theme_controller.dart';

const _target = 512;
const _storeLink =
    'https://play.google.com/store/apps/details?id=com.number.twofoureight';

class _Result {
  final bool success;
  final int moves;
  const _Result(this.success, this.moves);
}

/// The daily challenge: a date-seeded 2048 board, race to reach 512 in the
/// fewest moves. One attempt per day (resumes mid-run); shareable result.
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final DailyStore _store = DailyStore();

  int _puzzle = 0;
  int _streak = 0;
  DailyChallenge? _ch;
  _Result? _done;
  bool _loaded = false;

  List<TileMove> _moves = const [];
  Set<int> _popCells = const {};
  int _tick = 0;
  bool _busy = false;

  Offset _swipeAccum = Offset.zero;
  bool _swipeFired = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final today = DateTime.now();
    _puzzle = puzzleNumber(today);
    _streak = await _store.dailyStreak();
    final saved = await _store.load(_puzzle);

    if (saved != null && saved.finished) {
      if (mounted) {
        setState(() {
          _done = _Result(saved.success, saved.moves);
          _loaded = true;
        });
      }
      return;
    }

    final ch = DailyChallenge(
        seed: dailySeed(today), puzzleNumber: _puzzle, target: _target);
    if (saved != null) {
      for (final d in saved.history) {
        ch.move(d);
      }
    }
    if (mounted) {
      setState(() {
        _ch = ch;
        _popCells = _allCells(ch.state.board);
        _loaded = true;
      });
    }
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
    final ch = _ch;
    if (ch == null || _busy || ch.status != DailyStatus.playing) return;
    final previous = ch.state.board;
    final before = ch.moves;
    ch.move(dir);
    if (ch.moves == before) return; // no-op

    final moves = planMove(previous, dir);
    final preSpawn = applyMove(previous, dir).board;
    final pop = <int>{};
    for (final m in moves) {
      if (m.merged) pop.add(m.toRow * kBoardSize + m.toCol);
    }
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        if (preSpawn[r][c] == 0 && ch.state.board[r][c] != 0) {
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
    _store.saveInProgress(_puzzle, _target, ch.history);
    if (ch.status != DailyStatus.playing) _finish(ch);

    Future.delayed(const Duration(milliseconds: 110), () {
      if (mounted) setState(() => _busy = false);
    });
  }

  Future<void> _finish(DailyChallenge ch) async {
    final success = ch.status == DailyStatus.won;
    await _store.saveResult(_puzzle, success: success, moves: ch.moves);
    final streak = await _store.dailyStreak();
    if (mounted) {
      setState(() {
        _done = _Result(success, ch.moves);
        _streak = streak;
      });
    }
  }

  void _share() {
    final d = _done;
    if (d == null) return;
    Share.share(dailyShareText(
      puzzleNumber: _puzzle,
      target: _target,
      success: d.success,
      moves: d.moves,
      dailyStreak: _streak,
      link: _storeLink,
    ));
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
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _header(theme),
                              const SizedBox(height: 16),
                              if (_ch != null) _board(theme) else _doneFiller(theme),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_done != null) _resultOverlay(theme),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _header(GameTheme theme) {
    final c = theme.onBackground;
    final moves = _ch?.moves ?? _done?.moves ?? 0;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: c),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text('Daily #$_puzzle',
                  style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Text('🔥 $_streak',
                style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🎯 Goal: $_target',
                style: TextStyle(color: c, fontWeight: FontWeight.w700)),
            Text('Moves: $moves',
                style: TextStyle(color: c, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _board(GameTheme theme) {
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
          board: _ch!.state.board,
          moves: _moves,
          popCells: _popCells,
          tick: _tick,
        ),
      ),
    );
  }

  Widget _doneFiller(GameTheme theme) => const SizedBox(height: 40);

  Widget _resultOverlay(GameTheme theme) {
    final d = _done!;
    return Positioned.fill(
      child: Container(
        color: theme.overlayScrim,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: theme.dialogCard, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(d.success ? 'Solved! 🎉' : 'Out of moves',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                    d.success
                        ? 'Reached $_target in ${d.moves} moves'
                        : "Couldn't reach $_target today.",
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
                const SizedBox(height: 6),
                Text('🔥 $_streak day daily streak',
                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.primaryButtonText),
                    onPressed: _share,
                    icon: const Icon(Icons.share),
                    label: const Text('Share result',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Next puzzle in $_countdown',
                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
