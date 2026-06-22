import 'package:flutter/material.dart';

import '../../ads/banner_ad_box.dart';
import '../../ads/interstitial_ad.dart';
import '../../game/daily/daily_rotation.dart';
import '../../game/daily/daily_seed.dart';
import '../../game/daily/daily_share.dart';
import '../../game/daily/daily_store.dart';
import '../../game/progress_store.dart';
import '../../game/review_store.dart';
import '../engagement/review_prompt.dart';
import '../share_card.dart';
import '../theme_controller.dart';
import '../win_card.dart';
import 'daily_game.dart';
import 'daily_play_controller.dart';

/// Coins awarded once for successfully completing a day's daily challenge.
const int kDailyCompletionBonus = 100;

/// The daily challenge: one game per day on rotation (2048 → Number Tap →
/// Number Sort → Magic Square → repeat), under a shared Hero Banner chrome.
/// One attempt per day; only the finished result + streak persist.
class DailyScreen extends StatefulWidget {
  /// Overrides today's puzzle number (for tests). Production uses the date.
  final int? puzzleOverride;

  const DailyScreen({super.key, this.puzzleOverride});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final DailyStore _store = DailyStore();
  final ProgressStore _progressStore = ProgressStore();
  final ReviewStore _reviewStore = ReviewStore();
  final GlobalKey _shareKey = GlobalKey();
  late final DailyPlayController _controller;
  final InterstitialController _interstitial = InterstitialController();

  int _puzzle = 0;
  int _streak = 0;
  late DailyGame _game;
  DailySaved? _done;
  bool _loaded = false;
  bool _reviewEligible = false; // ask for a rating when the result is dismissed
  bool _showReview = false; // the review prompt is currently up

  @override
  void initState() {
    super.initState();
    _controller = DailyPlayController()..onComplete = _onComplete;
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _interstitial.dispose();
    super.dispose();
  }

  DailyGame _gameFor(int puzzle) =>
      kDailyGames[dailyGameId(puzzle)] ?? kDailyGames['2048']!;

  Future<void> _load() async {
    final today = DateTime.now();
    _puzzle = widget.puzzleOverride ?? puzzleNumber(today);
    _game = _gameFor(_puzzle);
    _streak = await _store.dailyStreak();
    final saved = await _store.load(_puzzle);
    if (mounted) {
      setState(() {
        _done = saved;
        _loaded = true;
      });
    }
  }

  Future<void> _onComplete(bool success, int score) async {
    await _store.saveResult(_puzzle, success: success, score: score);
    final streak = await _store.dailyStreak();

    // Award the daily-completion coin bonus once, only on a successful clear.
    if (success && await _store.grantBonusOnce(_puzzle)) {
      final progress = await _progressStore.load();
      await _progressStore
          .save(progress.copyWith(coins: progress.coins + kDailyCompletionBonus));
    }

    // A win is a good moment to ask for a rating — but only sometimes.
    var reviewEligible = false;
    if (success) {
      await _reviewStore.recordDailyWin();
      reviewEligible = await _reviewStore.shouldAsk(DateTime.now());
    }

    if (!mounted) return;
    setState(() {
      _done = DailySaved(success: success, score: score);
      _streak = streak;
      _reviewEligible = reviewEligible;
    });
    _interstitial.setPremium(ThemeScope.controllerOf(context).premiumUnlocked);
    _interstitial.onGameOver();
  }

  void _share() {
    final d = _done;
    if (d == null) return;
    shareResultImage(
      boundaryKey: _shareKey,
      text: dailyShareText(
        gameTitle: _game.title,
        puzzleNumber: _puzzle,
        result: _game.shareResult(d.success, d.score),
        dailyStreak: _streak,
        link: kStoreLink,
      ),
    );
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
          child: !_loaded
              ? Center(child: CircularProgressIndicator(color: theme.onBackground))
              : Column(
                  children: [
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _header(theme),
                                    const SizedBox(height: 14),
                                    _hero(theme),
                                    const SizedBox(height: 14),
                                    _game.buildPlay(dailySeed(DateTime.now()), _controller),
                                    const SizedBox(height: 12),
                                    _foot(theme),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_done != null) _shareCard(),
                          if (_done != null && !_showReview) _resultOverlay(theme),
                          if (_showReview) _reviewOverlay(),
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
    final c = theme.onBackground;
    return Row(
      children: [
        _circleButton(theme, Icons.arrow_back, () => Navigator.of(context).maybePop()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('DAILY #$_puzzle',
                style: TextStyle(
                    color: c, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.scoreBox,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.glassStroke, width: 1.2),
          ),
          child: Text('🔥 $_streak',
              style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 14)),
        ),
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
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: theme.onBackground, size: 20),
        ),
      ),
    );
  }

  Widget _hero(GameTheme theme) {
    final base = _game.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [base, Color.lerp(base, Colors.black, 0.30)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: base.withValues(alpha: 0.35), blurRadius: 22)],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -6,
            top: -10,
            child: Text(_game.emoji,
                style: TextStyle(fontSize: 84, color: Colors.white.withValues(alpha: 0.18))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⭐ TODAY\'S CHALLENGE',
                  style: TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
              const SizedBox(height: 2),
              Text(_game.title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(_game.goalText,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _metricChip(_game.goalChip),
                  const SizedBox(width: 10),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, _) => _metricChip(
                        '${_game.metricLabel} ${_game.formatMetric(_controller.metric)}'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
    );
  }

  Widget _foot(GameTheme theme) {
    return Text('Next puzzle in $_countdown',
        style: TextStyle(
            color: theme.onBackground.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w700));
  }

  Widget _shareCard() {
    final d = _done!;
    final stat = _game.resultStat(d.success, d.score);
    return OffscreenShareCard(
      boundaryKey: _shareKey,
      card: ShareCard(
        title: '${_game.title} Daily #$_puzzle',
        valueLabel: stat.label,
        value: stat.value,
        valueSub: stat.sub,
        badge: '🔥 $_streak day streak',
      ),
    );
  }

  Widget _resultOverlay(GameTheme theme) {
    final d = _done!;
    final stat = _game.resultStat(d.success, d.score);
    return WinCardOverlay(
      child: WinCard(
        celebrate: _game.celebrateOn(d.success),
        banner: d.success ? 'DAILY DONE' : null,
        headline: _game.resultHeadline(d.success),
        stat: WinStat(label: stat.label, value: stat.value, sub: stat.sub),
        badge: d.success
            ? '🪙 +$kDailyCompletionBonus  ·  🔥 $_streak day streak'
            : '🔥 $_streak day daily streak',
        primaryLabel: 'Share Result',
        primaryIcon: Icons.share,
        onPrimary: _share,
        footerLabel: 'Next daily in',
        footerValue: _countdown,
        onClose: _closeResult,
      ),
    );
  }

  /// Dismissing the result either asks for a rating (when due) or exits.
  void _closeResult() {
    if (_reviewEligible) {
      _reviewStore.markAsked(DateTime.now());
      setState(() {
        _reviewEligible = false;
        _showReview = true;
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Widget _reviewOverlay() {
    return ReviewPromptOverlay(
      coins: kDailyCompletionBonus,
      streak: _streak,
      onRate: () async {
        await requestAppReview();
        await _reviewStore.markRated();
        if (mounted) Navigator.of(context).maybePop();
      },
      onLater: () => Navigator.of(context).maybePop(),
    );
  }
}
