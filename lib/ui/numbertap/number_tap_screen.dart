import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/numbertap/number_tap_game.dart';
import '../../game/score_store.dart';
import '../theme_controller.dart';
import '../theme_picker.dart';

const _gold = Color(0xFFFFC93C);

// Tile gradients (blue / indigo / purple / magenta), assigned per cell.
const _tilePalette = <List<Color>>[
  [Color(0xFF4A6CF7), Color(0xFF3B4FD6)],
  [Color(0xFF7B5CFF), Color(0xFF5B3DF5)],
  [Color(0xFFA64CFF), Color(0xFF7B2FF7)],
  [Color(0xFFC74CCB), Color(0xFF9C27B0)],
  [Color(0xFF5C7CFF), Color(0xFF4458D0)],
];
const _greenGrad = [Color(0xFF7BE86B), Color(0xFF34C759)];

/// Number Tap Challenge: tap 1..25 in order as fast as you can. Best time
/// (elapsed + 2s per mistake) is saved.
class NumberTapScreen extends StatefulWidget {
  const NumberTapScreen({super.key});

  @override
  State<NumberTapScreen> createState() => _NumberTapScreenState();
}

class _NumberTapScreenState extends State<NumberTapScreen> {
  static const _gameId = 'numbertap';

  /// Highlight the next tile green only for the first numbers, then stop
  /// guiding so the rest is a real challenge.
  static const _guideUpTo = 10;

  final ScoreStore _store = ScoreStore();
  final Stopwatch _watch = Stopwatch();

  late NumberTapGame _game;
  Timer? _ticker;
  bool _started = false;
  int _flashCell = -1;
  int? _bestDeci;

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

  void _openSettings() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ThemePickerScreen()));

  String _fmt(int deci) => '${(deci / 10).toStringAsFixed(1)}s';

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _header(theme),
                        const SizedBox(height: 16),
                        _statsRow(theme),
                        const SizedBox(height: 14),
                        _banner(theme),
                        const SizedBox(height: 14),
                        _grid(theme),
                        const SizedBox(height: 14),
                        _hint(theme),
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
    return Row(
      children: [
        _circleButton(theme, Icons.arrow_back, () => Navigator.of(context).maybePop()),
        Expanded(
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: 'NUMBER ',
                      style: TextStyle(color: theme.onBackground)),
                  const TextSpan(text: 'TAP', style: TextStyle(color: _gold)),
                ],
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ),
        _circleButton(theme, Icons.settings, _openSettings),
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
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: theme.onBackground, size: 22),
        ),
      ),
    );
  }

  Widget _statsRow(GameTheme theme) {
    return Row(
      children: [
        Expanded(
          child: _statCard(theme, const Text('👑', style: TextStyle(fontSize: 24)),
              'Best Time', _bestDeci == null ? '--:--' : _fmt(_bestDeci!)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
              theme,
              Icon(Icons.timer_outlined, color: theme.onBackground, size: 24),
              'Time',
              _fmt(_elapsedDeci)),
        ),
      ],
    );
  }

  Widget _statCard(GameTheme theme, Widget icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scoreBox,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.glassStroke, width: 1.2),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: theme.scoreLabel)),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: theme.onBackground)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _banner(GameTheme theme) {
    final n = _game.isComplete ? 25 : _game.next;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.scoreBox,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.glassStroke, width: 1.2),
        boxShadow: [
          BoxShadow(color: _gold.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, -1)),
        ],
      ),
      child: Column(
        children: [
          Text('✨  TAP $n  ✨',
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.w900, color: theme.onBackground)),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Start by tapping number '),
                TextSpan(
                    text: '$n',
                    style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
              ],
              style: TextStyle(
                  fontSize: 14, color: theme.onBackground.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(GameTheme theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.boardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.glassStroke, width: 1.2),
      ),
      child: AspectRatio(
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
      ),
    );
  }

  Widget _cell(GameTheme theme, int index) {
    final number = _game.board[index];
    final cleared = _game.isCleared(number);
    final flashing = index == _flashCell;
    final isNext =
        !_game.isComplete && number == _game.next && _game.next <= _guideUpTo;

    if (cleared) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            color: theme.emptyCell,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    final grad = flashing
        ? const [Color(0xFFFF6B6B), Color(0xFFE53935)]
        : isNext
            ? _greenGrad
            : _tilePalette[index % _tilePalette.length];

    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: () => _onTap(number, index),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: grad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: isNext
                ? Border.all(color: const Color(0xFFB6FF6B), width: 2.5)
                : null,
            boxShadow: [
              if (isNext)
                BoxShadow(color: _greenGrad.last.withValues(alpha: 0.7), blurRadius: 14)
              else
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 5,
                    offset: const Offset(0, 3)),
            ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hint(GameTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scoreBox,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.glassStroke, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💡  ', style: TextStyle(fontSize: 16)),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Tap numbers in order:  '),
                  TextSpan(
                      text: '1 → 2 → 3 → …',
                      style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
                ],
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.onBackground.withValues(alpha: 0.9)),
              ),
            ),
          ),
        ],
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
