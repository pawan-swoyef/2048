import 'dart:math';

import 'package:flutter/material.dart';

import '../../ads/banner_ad_box.dart';
import '../../ads/interstitial_ad.dart';
import '../../ads/rewarded_ad.dart';
import '../../game/guide_store.dart';
import '../../game/numbersort/number_sort_game.dart';
import '../../game/numbersort/undo_allowance.dart';
import '../../game/numbersort/undo_store.dart';
import '../../game/score_store.dart';
import '../../game/sound_service.dart';
import '../paywall.dart';
import '../share_card.dart';
import '../theme_controller.dart';
import '../theme_picker.dart';
import '../win_card.dart';

const _gold = Color(0xFFFFC93C);
const _guideGreen = Color(0xFFB6FF6B);
const _guideGlow = Color(0xFF34C759);

// Each distinct number borrows a 2048 tile value so it takes a distinct color
// from the active theme's palette — keeping all 7 themes applied to this game.
const _numberSamples = [8, 32, 256, 64, 512, 16, 128];

/// Number Sort: drag the top number of a column onto a column whose top matches
/// (or an empty one) until every column is a single repeated number. Scored by
/// fewest moves. Undo is gated behind a rewarded ad (3/day) unless premium.
class NumberSortScreen extends StatefulWidget {
  /// Injectable starting board, for tests. Production uses a random board.
  final NumberSortGame? initialGame;

  const NumberSortScreen({super.key, this.initialGame});

  @override
  State<NumberSortScreen> createState() => _NumberSortScreenState();
}

class _NumberSortScreenState extends State<NumberSortScreen> {
  static const _gameId = 'numbersort';

  final ScoreStore _store = ScoreStore();
  final UndoStore _undoStore = UndoStore();
  final RewardedController _rewarded = RewardedController();
  final InterstitialController _interstitial = InterstitialController();
  final GlobalKey _shareKey = GlobalKey();
  final SoundService _sound = SoundService();

  late NumberSortGame _game;
  int? _bestMoves;
  UndoAllowance? _allowance;
  final GuideStore _guideStore = GuideStore();
  bool _guideActive = false;
  bool _soundOn = true;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame ?? NumberSortGame(Random());
    _loadBest();
    _loadGuide();
    _loadSound();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewarded.setPremium(_premium);
    _refreshAllowance();
  }

  @override
  void dispose() {
    _rewarded.dispose();
    _interstitial.dispose();
    _sound.dispose();
    super.dispose();
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

  bool get _premium => ThemeScope.controllerOf(context).premiumUnlocked;

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadBest() async {
    final b = await _store.bestFor(_gameId);
    if (mounted) setState(() => _bestMoves = b > 0 ? b : null);
  }

  Future<void> _loadGuide() async {
    final seen = await _guideStore.guideSeen(_gameId);
    if (mounted) setState(() => _guideActive = !seen);
  }

  Future<void> _refreshAllowance() async {
    final a = await _undoStore.allowance(premium: _premium, today: _todayStr());
    if (mounted) setState(() => _allowance = a);
  }

  void _move(int from, int to) {
    if (!_game.move(from, to)) return;
    setState(() {});
    if (_game.isComplete) {
      _finish();
    } else {
      _sound.move();
    }
  }

  Future<void> _finish() async {
    _sound.win();
    final m = _game.moves;
    if (_bestMoves == null || m < _bestMoves!) {
      await _store.saveBestFor(_gameId, m);
      if (mounted) setState(() => _bestMoves = m);
    } else {
      setState(() {});
    }
    if (_guideActive) {
      await _guideStore.markGuideSeen(_gameId);
      if (mounted) setState(() => _guideActive = false);
    }
    _interstitial.setPremium(_premium);
    _interstitial.onGameOver();
  }

  void _restart() {
    setState(() => _game = NumberSortGame(Random()));
  }

  /// Undo: instant for premium; for free players it plays a rewarded ad and
  /// spends one of the daily allowance, or opens the paywall once the cap is hit.
  void _onUndoTap() {
    if (!_game.canUndo) return;
    if (_premium) {
      setState(() => _game.undo());
      _sound.move();
      return;
    }
    final allowance = _allowance;
    if (allowance == null) return;
    if (!allowance.canUndo) {
      _openPaywall();
      return;
    }
    _rewarded.show(() async {
      if (!mounted) return;
      setState(() => _game.undo());
      _sound.move();
      await _undoStore.recordUndo(today: _todayStr());
      await _refreshAllowance();
    });
  }

  Future<void> _openPaywall() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
    if (mounted) await _refreshAllowance();
  }

  void _openSettings() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ThemePickerScreen()));

  void _share() {
    shareResultImage(
      boundaryKey: _shareKey,
      text: 'I solved Number Sort in ${_game.moves} moves! 🧩\n$kStoreLink',
    );
  }

  String _undoLabel() {
    if (_premium) return 'Undo';
    final a = _allowance;
    if (a == null) return 'Undo';
    if (a.remaining <= 0) return 'Undo 🔒';
    return 'Undo · ${a.remaining}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final guide = _guideActive && !_game.isComplete
        ? _game.suggestedMove()
        : null;
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
                              const SizedBox(height: 18),
                              _board(theme, guide),
                              const SizedBox(height: 18),
                              _controls(theme),
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
              if (!_premium) const BannerAdBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(GameTheme theme) {
    return Row(
      children: [
        _circleButton(
            theme, Icons.arrow_back, () => Navigator.of(context).maybePop()),
        Expanded(
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: 'NUMBER ',
                      style: TextStyle(color: theme.onBackground)),
                  const TextSpan(text: 'SORT', style: TextStyle(color: _gold)),
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
              'Best', _bestMoves == null ? '—' : '${_bestMoves!}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
              theme,
              Icon(Icons.swap_vert_rounded, color: theme.onBackground, size: 24),
              'Moves',
              '${_game.moves}'),
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
              Text(label, style: TextStyle(fontSize: 12, color: theme.scoreLabel)),
              Text(value,
                  key: label == 'Moves' ? const Key('sort-moves') : null,
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

  Widget _board(GameTheme theme, ({int from, int to})? guide) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.boardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.glassStroke, width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final n = _game.columns.length;
          const gap = 10.0;
          final colW = (c.maxWidth - gap * (n - 1)) / n;
          final tokenSize = (colW - 12).clamp(26.0, 70.0);
          // +22 leaves headroom for the first-game guide border (~5px) that
          // wraps the top token, so the column never overflows.
          final colH = (tokenSize + 6) * _game.height + 22;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                _column(theme, i, colW, colH, tokenSize, guide),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _column(GameTheme theme, int i, double w, double h, double tokenSize,
      ({int from, int to})? guide) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => _game.canMove(d.data, i),
      onAcceptWithDetails: (d) => _move(d.data, i),
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        final col = _game.columns[i];
        final isGuideTo = guide != null && guide.to == i;
        final container = Container(
          key: Key('sort-col-$i'),
          width: w,
          height: h,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: theme.emptyCell,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isGuideTo
                  ? _guideGreen
                  : active
                      ? theme.win
                      : theme.glassStroke,
              width: (isGuideTo || active) ? 2.6 : 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var pos = col.length - 1; pos >= 0; pos--)
                _tokenAt(theme, i, pos, tokenSize, guide),
            ],
          ),
        );
        if (!isGuideTo) return container;
        return KeyedSubtree(
          key: const Key('sort-guide-to'),
          child: container,
        );
      },
    );
  }

  Widget _tokenAt(GameTheme theme, int colIndex, int pos, double size,
      ({int from, int to})? guide) {
    final col = _game.columns[colIndex];
    final value = col[pos];
    final tile = _tokenTile(theme, value, size);
    final isTop = pos == col.length - 1;
    if (!isTop) return tile;
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
  }

  Widget _tokenTile(GameTheme theme, int value, double size,
      {bool dragging = false}) {
    final tc =
        theme.tileColors(_numberSamples[(value - 1) % _numberSamples.length]);
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tc.background, Color.lerp(tc.background, Colors.black, 0.22)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dragging ? 0.35 : 0.22),
            blurRadius: dragging ? 12 : 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w900,
            color: tc.text,
            shadows: const [
              Shadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 1))
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls(GameTheme theme) {
    return Row(
      children: [
        Expanded(
          child: _pillButton(
            theme,
            Icons.undo_rounded,
            _undoLabel(),
            _game.canUndo ? _onUndoTap : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _pillButton(
              theme, Icons.refresh_rounded, 'Restart', _restart),
        ),
      ],
    );
  }

  Widget _pillButton(
      GameTheme theme, IconData icon, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: theme.scoreBox,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.glassStroke, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: theme.onBackground, size: 20),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: theme.onBackground)),
              ],
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
            child: Text(
              'Drag a number onto a matching one or an empty column.',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.onBackground.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultOverlay(GameTheme theme) {
    final m = _game.moves;
    final isBest = _bestMoves != null && m <= _bestMoves!;
    return WinCardOverlay(
      child: WinCard(
        celebrate: true,
        banner: 'Solved!',
        headline: isBest ? 'New record! 🎉' : 'Solved it! 🎉',
        stat: WinStat(
          label: 'Solved in',
          value: '$m',
          sub: m == 1 ? 'move' : 'moves',
        ),
        badge: _bestMoves != null ? '👑 Best $_bestMoves moves' : null,
        primaryLabel: 'Play Again',
        primaryIcon: Icons.refresh,
        onPrimary: _restart,
        onShare: _share,
        onClose: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  Widget _shareCard() {
    return OffscreenShareCard(
      boundaryKey: _shareKey,
      card: ShareCard(
        title: 'Number Sort',
        valueLabel: 'Solved in',
        value: '${_game.moves}',
        valueSub: _game.moves == 1 ? 'move' : 'moves',
        badge: _bestMoves != null ? '👑 Best $_bestMoves moves' : null,
      ),
    );
  }
}
