import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/banner_ad_box.dart';
import '../ads/interstitial_ad.dart';
import '../ads/rewarded_ad.dart';
import '../game/board.dart';
import '../game/game_state.dart';
import '../game/numbersort/undo_allowance.dart';
import '../game/numbersort/undo_store.dart';
import '../game/save_store.dart';
import '../game/score_store.dart';
import '../game/sound_service.dart';
import 'animated_board.dart';
import 'dialogs.dart';
import 'game_buttons.dart';
import 'paywall.dart';
import 'score_header.dart';
import 'swipe.dart';
import 'share_card.dart';
import 'theme_controller.dart';
import 'theme_picker.dart';
import 'win_card.dart';

/// The single screen of the game.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _gameId = '2048';

  final Random _rng = Random();
  final ScoreStore _store = ScoreStore();
  final GameSaveStore _saveStore = GameSaveStore();
  final SoundService _sound = SoundService();
  final InterstitialController _interstitial = InterstitialController();
  final RewardedController _rewarded = RewardedController();
  late final UndoStore _undoStore;
  final GlobalKey _shareKey = GlobalKey();

  late GameState _state;
  final List<GameState> _history = []; // for undo (premium)
  List<TileMove> _moves = const [];
  Set<int> _popCells = const {};
  int _tick = 0;
  bool _busy = false;
  bool _soundOn = true;
  UndoAllowance? _allowance;

  // Mid-gesture swipe detection: fire a move as soon as the drag crosses a
  // small distance, instead of waiting for the finger to lift.
  Offset _swipeAccum = Offset.zero;
  bool _swipeFired = false;
  static const double _swipeThreshold = 22;

  static const int _maxUndoHistory = 50;

  @override
  void initState() {
    super.initState();
    _undoStore = UndoStore(gameId: '2048');
    _state = GameState.newGame(_rng);
    _popCells = _allTileCells(_state.board);
    _loadPrefs();
    _maybeResume();
  }

  /// Offers to continue a game left in progress (Home button / app closed). A
  /// fresh, untouched board (score 0) is never saved, so it never prompts.
  Future<void> _maybeResume() async {
    final saved = await _saveStore.load(_gameId);
    if (saved == null || !mounted) return;
    final GameState restored;
    try {
      restored = GameState.fromJson(saved);
    } catch (_) {
      await _saveStore.clear(_gameId);
      return;
    }
    if (restored.over || restored.score == 0) {
      await _saveStore.clear(_gameId);
      return;
    }
    if (!mounted) return;
    final resume = await confirmResume(context);
    if (!mounted) return;
    if (resume) {
      setState(() {
        _state = restored.withBest(_state.best);
        _history.clear();
        _moves = const [];
        _popCells = _allTileCells(_state.board);
        _tick++;
        _busy = false;
      });
    } else {
      await _saveStore.clear(_gameId);
    }
  }

  /// Saves the in-progress board, or clears the save once the game is over or
  /// back to an untouched start, so resume only offers a real game.
  void _persist() {
    if (_state.over || _state.score == 0) {
      _saveStore.clear(_gameId);
    } else {
      _saveStore.save(_gameId, _state.toJson());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rewarded.setPremium(_premium);
    _refreshAllowance();
  }

  @override
  void dispose() {
    _sound.dispose();
    _interstitial.dispose();
    _rewarded.dispose();
    super.dispose();
  }

  bool get _premium => ThemeScope.controllerOf(context).premiumUnlocked;

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshAllowance() async {
    final a = await _undoStore.allowance(premium: _premium, today: _todayStr());
    if (mounted) setState(() => _allowance = a);
  }

  Future<void> _loadPrefs() async {
    final best = await _store.bestFor('2048');
    final soundOn = await _store.loadSoundEnabled();
    if (!mounted) return;
    setState(() {
      _soundOn = soundOn;
      _sound.enabled = soundOn;
      if (best > _state.best) {
        _state =
            GameState(board: _state.board, score: _state.score, best: best);
      }
    });
  }

  void _toggleSound() {
    setState(() {
      _soundOn = !_soundOn;
      _sound.enabled = _soundOn;
    });
    _store.saveSoundEnabled(_soundOn);
  }

  void _openThemePicker() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ThemePickerScreen()),
    );
  }

  void _onSwipeStart() {
    _swipeAccum = Offset.zero;
    _swipeFired = false;
  }

  void _onSwipeUpdate(Offset delta) {
    if (_swipeFired) return;
    _swipeAccum += delta;
    final dir = swipeDirection(_swipeAccum, threshold: _swipeThreshold);
    if (dir != null) {
      _swipeFired = true;
      _move(dir);
    }
  }

  void _onSwipeEnd() => _swipeFired = false;

  void _move(Direction dir) {
    if (_busy) return;
    final previous = _state.board;
    final wasWon = _state.won;
    final next = _state.move(dir, _rng);
    if (identical(next, _state)) return; // no-op move

    // Save the pre-move state for undo (capped to bound memory).
    _history.add(_state);
    if (_history.length > _maxUndoHistory) _history.removeAt(0);

    final moves = planMove(previous, dir);
    final preSpawn = applyMove(previous, dir).board;
    final hasMerge = moves.any((m) => m.merged);

    final pop = <int>{};
    for (final m in moves) {
      if (m.merged) pop.add(m.toRow * kBoardSize + m.toCol);
    }
    // The spawned tile: the cell that filled in only after the slide resolved.
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        if (preSpawn[r][c] == 0 && next.board[r][c] != 0) {
          pop.add(r * kBoardSize + c);
        }
      }
    }

    setState(() {
      _state = next;
      _moves = moves;
      _popCells = pop;
      _tick++;
      _busy = true;
    });

    if (next.best > 0) _store.saveBestFor('2048', next.best);
    _persist();

    if (next.over) {
      _sound.lose();
      _interstitial.setPremium(ThemeScope.controllerOf(context).premiumUnlocked);
      _interstitial.onGameOver();
    } else if (next.won && !wasWon) {
      _sound.win();
    } else if (hasMerge) {
      _sound.merge();
    } else {
      _sound.move();
    }

    Future.delayed(const Duration(milliseconds: 110), () {
      if (mounted) setState(() => _busy = false);
    });
  }

  Future<void> _onNewGamePressed() async {
    if (_state.score > 0 && !_state.over) {
      final confirmed = await confirmNewGame(context);
      if (!confirmed) return;
    }
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _state = GameState.newGame(_rng, best: _state.best);
      _history.clear();
      _moves = const [];
      _popCells = _allTileCells(_state.board);
      _tick++;
      _busy = false;
    });
    _persist(); // fresh board (score 0) clears any stale save
  }

  void _undo() {
    if (_history.isEmpty || _busy) return;

    if (_premium) {
      final previous = _history.removeLast();
      setState(() {
        _state = previous.withBest(_state.best); // never lower the best score
        _moves = const [];
        _popCells = const {};
        _tick++;
      });
      _persist(); // undo can revive a game-over board; keep the save in sync
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
      if (_history.isEmpty) return;
      final previous = _history.removeLast();
      setState(() {
        _state = previous.withBest(_state.best);
        _moves = const [];
        _popCells = const {};
        _tick++;
      });
      _persist(); // undo can revive a game-over board; keep the save in sync
      await _undoStore.recordUndo(today: _todayStr());
      await _refreshAllowance();
    });
  }

  Future<void> _openPaywall() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
    if (mounted) await _refreshAllowance();
  }

  void _keepGoing() {
    setState(() => _state = _state.keepPlaying());
    _persist();
  }

  Set<int> _allTileCells(List<List<int>> board) {
    final cells = <int>{};
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        if (board[r][c] != 0) cells.add(r * kBoardSize + c);
      }
    }
    return cells;
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _move(Direction.left);
      case LogicalKeyboardKey.arrowRight:
        _move(Direction.right);
      case LogicalKeyboardKey.arrowUp:
        _move(Direction.up);
      case LogicalKeyboardKey.arrowDown:
        _move(Direction.down);
      default:
        return false;
    }
    return true;
  }

  /// Full-screen "Try Again" card shown when the board fills up. Offers an
  /// undo (revive) via the existing rewarded-ad flow, plus New Game / Home.
  Widget? _gameOverCard() {
    if (!_state.over) return null;
    final canUndo = _history.isNotEmpty;
    final isNewBest = _state.score > 0 && _state.score >= _state.best;
    return WinCardOverlay(
      child: WinCard(
        celebrate: false,
        mutedEmoji: '😵',
        banner: 'Game Over',
        headline: isNewBest ? 'New high score! 🎉' : 'So close!',
        stat: WinStat(
            label: 'Final score',
            value: '${_state.score}',
            sub: 'Best ${_state.best}'),
        badge: isNewBest ? '🏆 New Best!' : null,
        adActionLabel:
            canUndo ? (_premium ? 'Undo Last Move' : 'Undo · Watch Ad') : null,
        adActionIcon: canUndo
            ? (_premium ? Icons.undo_rounded : Icons.ondemand_video_rounded)
            : null,
        onAdAction: canUndo ? _undo : null,
        primaryLabel: 'New Game',
        primaryIcon: Icons.refresh_rounded,
        onPrimary: _startNewGame,
        onClose: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  void _shareWin() {
    shareResultImage(
      boundaryKey: _shareKey,
      text: 'I scored ${_state.score} and reached 2048! 🎉\n$kStoreLink',
    );
  }

  /// Full-screen celebration card when the player reaches 2048.
  Widget? _winCard() {
    if (!_state.won || _state.keepGoing) return null;
    return WinCardOverlay(
      child: WinCard(
        banner: 'You Win!',
        headline: 'You reached 2048! 🎉',
        stat: WinStat(label: 'Score', value: '${_state.score}'),
        primaryLabel: 'Keep Going',
        primaryIcon: Icons.play_arrow_rounded,
        onPrimary: _keepGoing,
        secondaryLabel: 'New Game',
        onSecondary: _startNewGame,
        onShare: _shareWin,
        onClose: _keepGoing,
      ),
    );
  }

  /// Off-screen branded image captured when the player shares their win.
  Widget _shareCard() {
    return OffscreenShareCard(
      boundaryKey: _shareKey,
      card: ShareCard(
        title: '2048',
        valueLabel: 'I reached',
        value: '2048',
        valueSub: 'Score ${_state.score}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameOverCard = _gameOverCard();
    final winCard = _winCard();
    final theme = ThemeScope.of(context);
    final premium = ThemeScope.controllerOf(context).premiumUnlocked;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          if (winCard != null) _shareCard(),
          Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Focus(
                autofocus: true,
                onKeyEvent: (node, event) => _handleKey(event)
                    ? KeyEventResult.handled
                    : KeyEventResult.ignored,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScoreHeader(score: _state.score, best: _state.best),
                      const SizedBox(height: 18),
                      _subRow(),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onHorizontalDragStart: (_) => _onSwipeStart(),
                        onHorizontalDragUpdate: (d) =>
                            _onSwipeUpdate(Offset(d.delta.dx, 0)),
                        onHorizontalDragEnd: (_) => _onSwipeEnd(),
                        onVerticalDragStart: (_) => _onSwipeStart(),
                        onVerticalDragUpdate: (d) =>
                            _onSwipeUpdate(Offset(0, d.delta.dy)),
                        onVerticalDragEnd: (_) => _onSwipeEnd(),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Stack(
                            children: [
                              AnimatedBoard(
                                board: _state.board,
                                moves: _moves,
                                popCells: _popCells,
                                tick: _tick,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _undoButton(theme, premium),
                      const SizedBox(height: 14),
                      Text(
                        'Swipe  ←  ↑  →  ↓  to move',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.onBackground.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
                ),
              ),
              if (!premium) const BannerAdBox(),
            ],
          ),
        ),
          ),
          ?winCard,
          ?gameOverCard,
        ],
      ),
    );
  }

  String _undoLabel() {
    if (_premium) return 'Undo';
    final a = _allowance;
    if (a == null) return 'Undo';
    if (a.remaining <= 0) return 'Undo';
    return 'Undo (${a.remaining})';
  }

  Widget _undoButton(GameTheme theme, bool premium) {
    final enabled = _history.isNotEmpty;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: theme.ghostButton,
        borderRadius: BorderRadius.circular(10),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? _undo : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.undo, size: 18, color: theme.onBackground),
                const SizedBox(width: 8),
                Text(
                  _undoLabel(),
                  style: TextStyle(
                    color: theme.onBackground,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (!premium) ...[
                  const SizedBox(width: 6),
                  if (_allowance != null && _allowance!.remaining <= 0)
                    const Icon(Icons.lock, size: 14, color: Color(0xFFFFD23F))
                  else
                    const Icon(Icons.play_circle_outline, size: 14, color: Color(0xFFFFD23F)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subRow() {
    final theme = ThemeScope.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Join the tiles, get to ',
              style: TextStyle(fontSize: 13, color: theme.onBackground),
              children: const [
                TextSpan(
                  text: '2048!',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconActionButton(
          icon: Icons.palette_outlined,
          onPressed: _openThemePicker,
        ),
        const SizedBox(width: 8),
        IconActionButton(
          icon: _soundOn ? Icons.volume_up : Icons.volume_off,
          onPressed: _toggleSound,
        ),
        const SizedBox(width: 8),
        IconActionButton(
          icon: Icons.help_outline,
          onPressed: () => showHowToPlay(context),
        ),
        const SizedBox(width: 8),
        PrimaryButton(label: 'New Game', onPressed: _onNewGamePressed),
      ],
    );
  }
}
