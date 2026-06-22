import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../ads/banner_ad_box.dart';
import '../../ads/interstitial_ad.dart';
import '../../game/guide_store.dart';
import '../../game/numbertap/number_tap_game.dart';
import '../../game/score_store.dart';
import '../../game/sound_service.dart';
import '../share_card.dart';
import '../theme_controller.dart';
import '../theme_picker.dart';
import '../win_card.dart';

const _gold = Color(0xFFFFC93C);

// Tiles take their colors from the active theme's tile palette (the same
// colors 2048 uses), so all 7 themes recolor this game too. These 2048 tile
// values give a varied, theme-appropriate spread.
const _themeSamples = [8, 16, 32, 64, 128, 256, 512];
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

  /// During the player's first-ever game, highlight the next tile green only for
  /// the first numbers, then stop guiding so the rest is a real challenge. After
  /// that first playthrough the guide never shows again.
  static const _guideUpTo = 10;

  final ScoreStore _store = ScoreStore();
  final GuideStore _guideStore = GuideStore();
  final Stopwatch _watch = Stopwatch();
  final GlobalKey _shareKey = GlobalKey();
  final InterstitialController _interstitial = InterstitialController();
  final SoundService _sound = SoundService();

  late NumberTapGame _game;
  Timer? _ticker;
  bool _started = false;
  int _flashCell = -1;
  int? _bestDeci;
  bool _soundOn = true;
  bool _guideActive = false;

  @override
  void initState() {
    super.initState();
    _game = NumberTapGame(Random());
    _loadBest();
    _loadSound();
    _loadGuide();
  }

  Future<void> _loadGuide() async {
    final seen = await _guideStore.guideSeen(_gameId);
    if (mounted) setState(() => _guideActive = !seen);
  }

  Future<void> _loadBest() async {
    final b = await _store.bestFor(_gameId);
    if (mounted) setState(() => _bestDeci = b > 0 ? b : null);
  }

  Future<void> _loadSound() async {
    final on = await _store.loadSoundEnabled();
    if (!mounted) return;
    setState(() {
      _soundOn = on;
      _sound.enabled = on;
    });
  }

  void _toggleSound() {
    setState(() {
      _soundOn = !_soundOn;
      _sound.enabled = _soundOn;
    });
    _store.saveSoundEnabled(_soundOn);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _interstitial.dispose();
    _sound.dispose();
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
      _sound.gameOver();
      setState(() => _flashCell = cellIndex);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _flashCell = -1);
      });
    } else if (!_game.isComplete) {
      _sound.merge();
    }
    if (_game.isComplete) _finish();
  }

  Future<void> _finish() async {
    _watch.stop();
    _ticker?.cancel();
    _sound.win();
    if (_guideActive) {
      await _guideStore.markGuideSeen(_gameId);
      if (mounted) setState(() => _guideActive = false);
    }
    final time = _elapsedDeci;
    if (_bestDeci == null || time < _bestDeci!) {
      await _store.saveBestFor(_gameId, time);
      if (mounted) setState(() => _bestDeci = time);
    } else {
      setState(() {});
    }
    if (!mounted) return;
    _interstitial.setPremium(ThemeScope.controllerOf(context).premiumUnlocked);
    _interstitial.onGameOver();
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

  void _share() {
    final time = _fmt(_elapsedDeci);
    final misses = _game.mistakes;
    final missText = misses > 0 ? ' ($misses misses)' : '';
    shareResultImage(
      boundaryKey: _shareKey,
      text: 'I cleared Number Tap in $time$missText! ⚡\n$kStoreLink',
    );
  }

  void _openSettings() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ThemePickerScreen()));

  String _fmt(int deci) => '${(deci / 10).toStringAsFixed(1)}s';

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final premium = ThemeScope.controllerOf(context).premiumUnlocked;
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
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (_game.isComplete) _shareCard(),
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
              if (!premium) const BannerAdBox(),
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
        _circleButton(theme,
            _soundOn ? Icons.volume_up : Icons.volume_off, _toggleSound),
        const SizedBox(width: 8),
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
    final isNext = _guideActive &&
        !_game.isComplete &&
        number == _game.next &&
        _game.next <= _guideUpTo;

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

    final tc = theme.tileColors(_themeSamples[index % _themeSamples.length]);
    final grad = flashing
        ? const [Color(0xFFFF6B6B), Color(0xFFE53935)]
        : isNext
            ? _greenGrad
            : [tc.background, Color.lerp(tc.background, Colors.black, 0.22)!];
    final textColor = (flashing || isNext) ? Colors.white : tc.text;

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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: textColor,
                shadows: const [
                  Shadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 1))
                ],
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
    return WinCardOverlay(
      child: WinCard(
        celebrate: isBest,
        banner: isBest ? 'New Best!' : 'Done!',
        headline: isBest ? 'New record! 🎉' : 'Great job! 🎉',
        stat: WinStat(
          label: 'Your time',
          value: _fmt(time),
          sub: _game.mistakes > 0
              ? '${_game.mistakes} misses · +${_game.penaltySeconds}s'
              : 'no mistakes',
        ),
        badge: _bestDeci != null ? '👑 Best ${_fmt(_bestDeci!)}' : null,
        primaryLabel: 'Play Again',
        primaryIcon: Icons.refresh,
        onPrimary: _playAgain,
        onShare: _share,
        onClose: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  Widget _shareCard() {
    final time = _fmt(_elapsedDeci);
    return OffscreenShareCard(
      boundaryKey: _shareKey,
      card: ShareCard(
        title: 'Number Tap',
        valueLabel: 'Your time',
        value: time,
        valueSub: _game.mistakes > 0
            ? '${_game.mistakes} misses · +${_game.penaltySeconds}s'
            : 'no mistakes',
        badge: _bestDeci != null ? '👑 Best ${_fmt(_bestDeci!)}' : null,
      ),
    );
  }
}
