import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/numbertap/number_tap_game.dart';
import '../../game/score_store.dart';
import '../theme_controller.dart';

/// Number Tap Challenge: tap 1..25 in order as fast as you can. Best time
/// (elapsed + 2s per mistake) is saved.
class NumberTapScreen extends StatefulWidget {
  const NumberTapScreen({super.key});

  @override
  State<NumberTapScreen> createState() => _NumberTapScreenState();
}

class _NumberTapScreenState extends State<NumberTapScreen> {
  static const _gameId = 'numbertap';

  final ScoreStore _store = ScoreStore();
  final Stopwatch _watch = Stopwatch();

  late NumberTapGame _game;
  Timer? _ticker;
  bool _started = false;
  int _flashCell = -1;
  int? _bestDeci; // best time in deciseconds (lower is better)

  @override
  void initState() {
    super.initState();
    _game = NumberTapGame(Random());
    _loadBest();
  }

  Future<void> _loadBest() async {
    final b = await _store.bestFor(_gameId);
    if (mounted) setState(() => _bestDeci = b > 0 ? b : null);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Elapsed time + penalties, in deciseconds.
  int get _elapsedDeci =>
      (_watch.elapsedMilliseconds / 100).round() + _game.penaltySeconds * 10;

  void _onTap(int number, int cellIndex) {
    if (_game.isComplete) return;
    if (!_started) {
      _started = true;
      _watch.start();
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted && !_game.isComplete) setState(() {});
      });
    }
    final wasCorrect = number == _game.next;
    setState(() => _game.tap(number));
    if (!wasCorrect) {
      setState(() => _flashCell = cellIndex);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _flashCell = -1);
      });
    }
    if (_game.isComplete) _finish();
  }

  Future<void> _finish() async {
    _watch.stop();
    _ticker?.cancel();
    final time = _elapsedDeci;
    if (_bestDeci == null || time < _bestDeci!) {
      await _store.saveBestFor(_gameId, time);
      if (mounted) setState(() => _bestDeci = time);
    } else {
      setState(() {});
    }
  }

  void _playAgain() {
    setState(() {
      _game = NumberTapGame(Random());
      _watch
        ..stop()
        ..reset();
      _started = false;
      _flashCell = -1;
    });
  }

  String _fmt(int deci) => '${(deci / 10).toStringAsFixed(1)}s';

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
          child: Stack(
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
                        _grid(theme),
                      ],
                    ),
                  ),
                ),
              ),
              if (_game.isComplete) _resultOverlay(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(GameTheme theme) {
    final c = theme.onBackground;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: c),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text('Number Tap',
                  style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Icon(Icons.timer_outlined, size: 18, color: c.withValues(alpha: 0.85)),
            const SizedBox(width: 4),
            Text(_fmt(_elapsedDeci),
                style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        Text('Tap ${_game.isComplete ? 25 : _game.next}',
            style: TextStyle(color: c, fontSize: 26, fontWeight: FontWeight.w900)),
        Text(
          _bestDeci == null ? 'No best time yet' : 'Best: ${_fmt(_bestDeci!)}',
          style: TextStyle(color: c.withValues(alpha: 0.8), fontSize: 13),
        ),
      ],
    );
  }

  Widget _grid(GameTheme theme) {
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          for (var r = 0; r < 5; r++)
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < 5; col++)
                    Expanded(child: _cell(theme, r * 5 + col)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(GameTheme theme, int index) {
    final number = _game.board[index];
    final cleared = _game.isCleared(number);
    final flashing = index == _flashCell;

    Color bg = theme.scoreBox;
    if (flashing) {
      bg = const Color(0xFFFF5B5B);
    } else if (cleared) {
      bg = theme.emptyCell;
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: cleared ? null : () => _onTap(number, index),
          child: Center(
            child: Text(
              cleared ? '' : '$number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: flashing ? Colors.white : theme.onBackground,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultOverlay(GameTheme theme) {
    final time = _elapsedDeci;
    final isBest = _bestDeci != null && time <= _bestDeci!;
    return Positioned.fill(
      child: Container(
        color: theme.overlayScrim,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.dialogCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isBest ? 'New Best! 🎉' : 'Done! 🎉',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Time: ${_fmt(time)}',
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                if (_game.mistakes > 0)
                  Text('(${_game.mistakes} misses · +${_game.penaltySeconds}s)',
                      style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.primaryButtonText,
                    ),
                    onPressed: _playAgain,
                    child: const Text('Play Again',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
