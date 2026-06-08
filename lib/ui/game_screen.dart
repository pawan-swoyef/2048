import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ads/banner_ad_box.dart';
import '../ads/interstitial_ad.dart';
import '../game/board.dart';
import '../game/daily_engagement.dart';
import '../game/game_state.dart';
import '../game/progress_store.dart';
import '../game/score_store.dart';
import '../game/sound_service.dart';
import 'animated_board.dart';
import 'dialogs.dart';
import 'engagement/coin_pill.dart';
import 'engagement/daily_gift_button.dart';
import 'engagement/daily_gift_dialog.dart';
import 'engagement/reward_toast.dart';
import 'engagement/streak_pill.dart';
import 'engagement/streak_sheet.dart';
import 'game_buttons.dart';
import 'overlays.dart';
import 'paywall.dart';
import 'score_header.dart';
import 'theme_controller.dart';
import 'theme_picker.dart';

/// The single screen of the game.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Random _rng = Random();
  final ScoreStore _store = ScoreStore();
  final ProgressStore _progressStore = ProgressStore();
  final SoundService _sound = SoundService();
  final InterstitialController _interstitial = InterstitialController();

  PlayerProgress _progress = const PlayerProgress();

  late GameState _state;
  final List<GameState> _history = []; // for undo (premium)
  List<TileMove> _moves = const [];
  Set<int> _popCells = const {};
  int _tick = 0;
  bool _busy = false;
  bool _soundOn = true;

  static const int _maxUndoHistory = 50;

  @override
  void initState() {
    super.initState();
    _state = GameState.newGame(_rng);
    _popCells = _allTileCells(_state.board);
    _loadPrefs();
    _loadEngagement();
  }

  @override
  void dispose() {
    _sound.dispose();
    _interstitial.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final best = await _store.loadBest();
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

  Future<void> _loadEngagement() async {
    final loaded = await _progressStore.load();
    final result = applyDailyOpen(loaded, DateTime.now());
    await _progressStore.save(result.progress);
    if (!mounted) return;
    setState(() => _progress = result.progress);
  }

  void _openStreakSheet() {
    showDialog<void>(
      context: context,
      builder: (_) => StreakSheet(progress: _progress),
    );
  }

  void _openDailyGift() {
    final today = DateTime.now();
    showDialog<void>(
      context: context,
      builder: (_) => DailyGiftDialog(
        progress: _progress,
        today: today,
        onClaim: () => _claimDailyGift(today),
      ),
    );
  }

  Future<void> _claimDailyGift(DateTime today) async {
    if (!giftAvailable(_progress, today)) return;
    final updated = claimGift(_progress, today);
    final earned = updated.coins - _progress.coins;
    await _progressStore.save(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
    setState(() => _progress = updated);
    showCoinToast(context, earned);
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

    if (next.best > 0) _store.saveBest(next.best);

    if (next.over) {
      _sound.gameOver();
      _interstitial.setPremium(ThemeScope.controllerOf(context).premiumUnlocked);
      _interstitial.onGameOver();
    } else if (next.won && !wasWon) {
      _sound.win();
    } else if (hasMerge) {
      _sound.merge();
    } else {
      _sound.move();
    }

    Future.delayed(const Duration(milliseconds: 170), () {
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
  }

  void _undo() {
    final controller = ThemeScope.controllerOf(context);
    if (!controller.premiumUnlocked) {
      // Undo is a premium feature — send free users to the paywall.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    if (_history.isEmpty || _busy) return;
    final previous = _history.removeLast();
    setState(() {
      _state = previous.withBest(_state.best); // never lower the best score
      _moves = const [];
      _popCells = const {};
      _tick++;
    });
  }

  void _keepGoing() => setState(() => _state = _state.keepPlaying());

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

  Widget? _overlay() {
    if (_state.over) {
      return GameOverOverlay(score: _state.score, onTryAgain: _startNewGame);
    }
    if (_state.won && !_state.keepGoing) {
      return WinOverlay(onKeepGoing: _keepGoing, onNewGame: _startNewGame);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final overlay = _overlay();
    final theme = ThemeScope.of(context);
    final premium = ThemeScope.controllerOf(context).premiumUnlocked;

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
                      if (_progress.streakCurrent > 0) ...[
                        const SizedBox(height: 14),
                        _statRow(),
                      ],
                      const SizedBox(height: 18),
                      _subRow(),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onHorizontalDragEnd: (d) {
                          final v = d.primaryVelocity ?? 0;
                          if (v > 0) _move(Direction.right);
                          if (v < 0) _move(Direction.left);
                        },
                        onVerticalDragEnd: (d) {
                          final v = d.primaryVelocity ?? 0;
                          if (v > 0) _move(Direction.down);
                          if (v < 0) _move(Direction.up);
                        },
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
                              if (overlay != null)
                                Positioned.fill(child: overlay),
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
    );
  }

  Widget _undoButton(GameTheme theme, bool premium) {
    final enabled = premium ? _history.isNotEmpty : true;
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
                  'Undo',
                  style: TextStyle(
                    color: theme.onBackground,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                if (!premium) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.lock, size: 14, color: Color(0xFFFFD23F)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow() {
    return Row(
      children: [
        StreakPill(streak: _progress.streakCurrent, onTap: _openStreakSheet),
        const SizedBox(width: 8),
        CoinPill(coins: _progress.coins),
        const Spacer(),
        DailyGiftButton(
          available: giftAvailable(_progress, DateTime.now()),
          onTap: _openDailyGift,
        ),
      ],
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
