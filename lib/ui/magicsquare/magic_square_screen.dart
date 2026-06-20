import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../ads/rewarded_ad.dart';
import '../../game/guide_store.dart';
import '../../game/magicsquare/hint_allowance.dart';
import '../../game/magicsquare/hint_store.dart';
import '../../game/magicsquare/magic_square_game.dart';
import '../../game/score_store.dart';
import '../paywall.dart';
import '../share_card.dart';
import '../theme_controller.dart';
import '../theme_picker.dart';
import '../win_card.dart';
import 'hint_choice_dialog.dart';

const _gold = Color(0xFFFFC93C);
const _magicGreen = Color(0xFF34C759);
const _wrongOrange = Color(0xFFFF8A5C);
const _guideGreen = Color(0xFFB6FF6B);

// Each number 1..9 borrows a 2048 tile value so it takes a distinct color from
// the active theme's palette — keeping all 7 themes applied to this game.
const _numberSamples = [2, 4, 8, 16, 32, 64, 128, 256, 512];

/// What a drag is carrying: either a number lifted from the tray, or a number
/// being moved out of a board cell.
class _Drag {
  final int? value; // set when dragging from the tray
  final int? fromCell; // set when dragging a placed number
  const _Drag.fromTray(this.value) : fromCell = null;
  const _Drag.fromCell(this.fromCell) : value = null;
}

/// Magic Square: drag 1..9 into a 3x3 grid so every row, column, and diagonal
/// sums to 15. Best solve time is saved. Hints are gated behind a rewarded ad
/// (1/day) or premium.
class MagicSquareScreen extends StatefulWidget {
  /// Injectable starting board, for tests. Production uses a random board.
  final MagicSquareGame? initialGame;

  const MagicSquareScreen({super.key, this.initialGame});

  @override
  State<MagicSquareScreen> createState() => _MagicSquareScreenState();
}

class _MagicSquareScreenState extends State<MagicSquareScreen> {
  static const _gameId = 'magicsquare';

  final ScoreStore _store = ScoreStore();
  final HintStore _hintStore = HintStore();
  final RewardedController _rewarded = RewardedController();
  final Stopwatch _watch = Stopwatch();
  final GlobalKey _shareKey = GlobalKey();

  late MagicSquareGame _game;
  Timer? _ticker;
  bool _started = false;
  int? _bestDeci;
  HintAllowance? _allowance;
  final GuideStore _guideStore = GuideStore();
  bool _guideActive = false;

  @override
  void initState() {
    super.initState();
    _game = widget.initialGame ?? MagicSquareGame(Random());
    _loadBest();
    _loadGuide();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewarded.setPremium(_premium);
    _refreshAllowance();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _rewarded.dispose();
    super.dispose();
  }

  bool get _premium => ThemeScope.controllerOf(context).premiumUnlocked;

  int get _elapsedDeci => (_watch.elapsedMilliseconds / 100).round();

  String _fmt(int deci) => '${(deci / 10).toStringAsFixed(1)}s';

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadBest() async {
    final b = await _store.bestFor(_gameId);
    if (mounted) setState(() => _bestDeci = b > 0 ? b : null);
  }

  Future<void> _loadGuide() async {
    final seen = await _guideStore.guideSeen(_gameId);
    if (mounted) setState(() => _guideActive = !seen);
  }

  Future<void> _refreshAllowance() async {
    final a = await _hintStore.allowance(premium: _premium, today: _todayStr());
    if (mounted) setState(() => _allowance = a);
  }

  void _ensureStarted() {
    if (_started || _game.isComplete) return;
    _started = true;
    _watch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && !_game.isComplete) setState(() {});
    });
  }

  void _afterChange() {
    _ensureStarted();
    setState(() {});
    if (_game.isComplete) _finish();
  }

  void _place(int value, int cell) {
    if (_game.place(value, cell)) _afterChange();
  }

  void _move(int from, int to) {
    if (_game.move(from, to)) _afterChange();
  }

  void _removeAt(int cell) {
    if (_game.removeAt(cell) != null) setState(() {});
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
    if (_guideActive) {
      await _guideStore.markGuideSeen(_gameId);
      if (mounted) setState(() => _guideActive = false);
    }
  }

  void _newPuzzle() {
    setState(() {
      _game = MagicSquareGame(Random());
      _watch
        ..stop()
        ..reset();
      _started = false;
    });
  }

  Future<void> _onHintTap() async {
    if (_game.isComplete) return;
    if (_premium) {
      _doHint();
      return;
    }
    final a = _allowance;
    if (a == null) return;
    final choice = await showHintChoiceDialog(context, showWatchAd: a.canHint);
    if (!mounted || choice == null) return;
    if (choice == HintChoice.goPremium) {
      await _openPaywall();
    } else {
      _rewarded.show(() async {
        if (!mounted) return;
        _doHint();
        await _hintStore.recordHint(today: _todayStr());
        await _refreshAllowance();
      });
    }
  }

  void _doHint() {
    _game.hint();
    _afterChange();
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
      text: 'I solved a Magic Square in ${_fmt(_elapsedDeci)}! 🔢\n$kStoreLink',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final guide = _guideActive && !_game.isComplete
        ? _game.suggestedPlacement()
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
                        const SizedBox(height: 16),
                        _board(theme, guide),
                        const SizedBox(height: 14),
                        _tray(theme, guide),
                        const SizedBox(height: 16),
                        _controls(theme),
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
        _circleButton(
            theme, Icons.arrow_back, () => Navigator.of(context).maybePop()),
        Expanded(
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: 'MAGIC ',
                      style: TextStyle(color: theme.onBackground)),
                  const TextSpan(text: 'SQUARE', style: TextStyle(color: _gold)),
                ],
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
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
              'Best Time', _bestDeci == null ? '--' : _fmt(_bestDeci!)),
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
              Text(label, style: TextStyle(fontSize: 12, color: theme.scoreLabel)),
              Text(value,
                  key: label == 'Time' ? const Key('ms-time') : null,
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

  /// Crossword-style frame: column sums run along the top edge, row sums down
  /// the left edge, the "=15" target sits in the corner, and the two diagonals
  /// get a small strip beneath the grid.
  Widget _board(GameTheme theme, ({int value, int cell})? guide) {
    const track = 30.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.glassStroke, width: 1.2),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 30,
            child: Row(
              children: [
                const SizedBox(
                  width: track,
                  child: Center(
                    child: Text('=15',
                        style: TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                for (var col = 0; col < 3; col++)
                  Expanded(child: _frameSum(MagicSquareGame.lines[3 + col])),
              ],
            ),
          ),
          for (var r = 0; r < 3; r++)
            Row(
              children: [
                SizedBox(
                    width: track, child: _frameSum(MagicSquareGame.lines[r])),
                for (var col = 0; col < 3; col++)
                  Expanded(child: _cell(theme, r * 3 + col, guide)),
              ],
            ),
          const SizedBox(height: 8),
          _diagStrip(theme),
        ],
      ),
    );
  }

  /// A row/column sum sitting on the dark frame: white normally, green when the
  /// line already sums to 15, orange when it's full but wrong.
  Widget _frameSum(List<int> line) {
    final magic = _game.lineIsMagic(line);
    final wrong = _game.lineComplete(line) && !magic;
    final color = magic
        ? _magicGreen
        : wrong
            ? _wrongOrange
            : Colors.white;
    return Center(
      child: Text('${_game.lineSum(line)}',
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w900, color: color)),
    );
  }

  Widget _diagStrip(GameTheme theme) {
    Widget chip(List<int> line, String glyph) {
      final magic = _game.lineIsMagic(line);
      final wrong = _game.lineComplete(line) && !magic;
      final color = magic
          ? _magicGreen
          : wrong
              ? _wrongOrange
              : Colors.white.withValues(alpha: 0.85);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.glassStroke, width: 1),
        ),
        child: Text('$glyph ${_game.lineSum(line)}',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        chip(MagicSquareGame.lines[6], '↘'),
        const SizedBox(width: 10),
        chip(MagicSquareGame.lines[7], '↙'),
      ],
    );
  }

  Widget _cell(GameTheme theme, int index, ({int value, int cell})? guide) {
    final value = _game.grid[index];
    final isClue = _game.clue[index];
    final isGuide = guide != null && guide.cell == index;
    return DragTarget<_Drag>(
      onWillAcceptWithDetails: (d) {
        final data = d.data;
        if (data.value != null) return _game.canPlace(data.value!, index);
        return !isClue && value == null && !_game.clue[data.fromCell!];
      },
      onAcceptWithDetails: (d) {
        final data = d.data;
        if (data.value != null) {
          _place(data.value!, index);
        } else {
          _move(data.fromCell!, index);
        }
      },
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.all(4),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              key: Key('ms-cell-$index'),
              decoration: BoxDecoration(
                color: value == null ? theme.emptyCell : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isGuide
                      ? _guideGreen
                      : active
                          ? theme.win
                          : theme.glassStroke,
                  width: (isGuide || active) ? 2.6 : 1.2,
                ),
              ),
              child: value == null
                  ? (isGuide
                      ? const SizedBox.expand(key: Key('ms-guide-cell'))
                      : null)
                  : _numberTile(theme, value, isClue: isClue, cell: index),
            ),
          ),
        );
      },
    );
  }

  /// A filled number tile. Clues are locked; player-placed ones are draggable
  /// (to move between cells or back to the tray).
  Widget _numberTile(GameTheme theme, int value,
      {required bool isClue, required int cell}) {
    final tile = _tile(theme, value, isClue: isClue);
    if (isClue) return tile;
    return Draggable<_Drag>(
      data: _Drag.fromCell(cell),
      feedback: _tile(theme, value, dragging: true),
      childWhenDragging: Opacity(opacity: 0.3, child: tile),
      child: tile,
    );
  }

  Widget _tile(GameTheme theme, int value,
      {bool isClue = false, bool dragging = false}) {
    final tc =
        theme.tileColors(_numberSamples[(value - 1) % _numberSamples.length]);
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tc.background, Color.lerp(tc.background, Colors.black, 0.22)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: isClue
            ? Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dragging ? 0.35 : 0.22),
            blurRadius: dragging ? 12 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Text('$value',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w900, color: tc.text)),
          ),
          if (isClue)
            Positioned(
              right: 3,
              top: 3,
              child: Icon(Icons.lock,
                  size: 11, color: tc.text.withValues(alpha: 0.7)),
            ),
        ],
      ),
    );
  }

  Widget _tray(GameTheme theme, ({int value, int cell})? guide) {
    return DragTarget<_Drag>(
      onWillAcceptWithDetails: (d) => d.data.fromCell != null,
      onAcceptWithDetails: (d) => _removeAt(d.data.fromCell!),
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.scoreBox,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? theme.win : theme.glassStroke,
              width: active ? 2.4 : 1.2,
            ),
          ),
          child: _game.tray.isEmpty
              ? Center(
                  child: Text('Drag a number back here to remove it',
                      style: TextStyle(fontSize: 12, color: theme.scoreLabel)))
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final value in _game.tray)
                      _trayChip(theme, value, guide),
                  ],
                ),
        );
      },
    );
  }

  Widget _trayChip(GameTheme theme, int value, ({int value, int cell})? guide) {
    final chip = SizedBox(
      width: 54,
      height: 54,
      child: _tile(theme, value),
    );
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
  }

  Widget _controls(GameTheme theme) {
    return Row(
      children: [
        Expanded(
          child: _pillButton(theme, Icons.lightbulb_outline_rounded,
              _hintLabel(), const Key('ms-hint'), _onHintTap),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _pillButton(theme, Icons.refresh_rounded, 'New', null,
              _newPuzzle),
        ),
      ],
    );
  }

  String _hintLabel() {
    if (_premium) return 'Hint';
    final a = _allowance;
    if (a != null && a.canHint) return 'Hint · 1';
    return 'Hint';
  }

  Widget _pillButton(GameTheme theme, IconData icon, String label, Key? key,
      VoidCallback onTap) {
    return Material(
      color: theme.scoreBox,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: key,
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
    );
  }

  Widget _resultOverlay(GameTheme theme) {
    final time = _elapsedDeci;
    final isBest = _bestDeci != null && time <= _bestDeci!;
    return WinCardOverlay(
      child: WinCard(
        celebrate: true,
        banner: 'Solved!',
        headline: isBest ? 'New record! 🎉' : 'Magic! 🎉',
        stat: WinStat(label: 'Your time', value: _fmt(time)),
        badge: _bestDeci != null ? '👑 Best ${_fmt(_bestDeci!)}' : null,
        primaryLabel: 'New Puzzle',
        primaryIcon: Icons.refresh,
        onPrimary: _newPuzzle,
        onShare: _share,
        onClose: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  Widget _shareCard() {
    return OffscreenShareCard(
      boundaryKey: _shareKey,
      card: ShareCard(
        title: 'Magic Square',
        valueLabel: 'Your time',
        value: _fmt(_elapsedDeci),
        badge: _bestDeci != null ? '👑 Best ${_fmt(_bestDeci!)}' : null,
      ),
    );
  }
}
