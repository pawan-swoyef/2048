import 'dart:math';

import 'package:flutter/material.dart';

import '../../ads/banner_ad_box.dart';
import '../../game/daily_engagement.dart';
import '../../game/progress_store.dart';
import '../../game/score_store.dart';
import '../../game/sound_service.dart';
import '../engagement/animated_coin_count.dart';
import '../engagement/coin_burst.dart';
import '../engagement/daily_reward_screen.dart';
import '../engagement/engagement_style.dart';
import '../engagement/streak_sheet.dart';
import '../paywall.dart';
import '../theme_controller.dart';
import '../theme_picker.dart';
import 'all_games_screen.dart';
import 'game_card.dart';
import 'game_registry.dart';

// Text colors used on the white cards (kept readable across themes).
const _cardTitle = Color(0xFF241139);
const _cardSub = Color(0xFF8A7CA8);
const _accent = Color(0xFF6A2DBF);

/// The home hub: a polished landing screen with the engagement stats, a
/// featured game, and a bottom nav. The app opens here.
class HubScreen extends StatefulWidget {
  const HubScreen({super.key, this.featuredGameId});

  /// Forces which game is spotlighted in the highlight. Only for tests; in the
  /// app the featured game is picked at random on each open.
  @visibleForTesting
  final String? featuredGameId;

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final ProgressStore _progressStore = ProgressStore();
  final ScoreStore _scoreStore = ScoreStore();
  final SoundService _sound = SoundService();

  // Targets the coin-balance pill so collected coins can fly into it.
  final GlobalKey _coinPillKey = GlobalKey();
  final GlobalKey _giftKey = GlobalKey();

  // Bumped to make the coin count snap (no animation) when the source screen
  // already animated the collect; left unchanged when the hub should count up.
  int _coinEpoch = 0;

  static const _statValueStyle =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _cardTitle);

  PlayerProgress _progress = const PlayerProgress();
  final Map<String, int> _bests = {};

  // 0 = Home, 1 = All Games. The bottom nav switches between the two.
  int _tab = 0;

  // The game spotlighted in the home highlight. Picked at random from the
  // regular games (everything except the Daily Challenge, which has its own
  // pinned card) each time the hub opens, so it's not always 2048.
  late final GameInfo _featured;

  @override
  void initState() {
    super.initState();
    _featured = _pickFeatured();
    _loadEngagement();
    _loadBests();
    _loadSound();
  }

  Future<void> _loadSound() async {
    final on = await _scoreStore.loadSoundEnabled();
    _sound.enabled = on;
  }

  @override
  void dispose() {
    _sound.dispose();
    super.dispose();
  }

  GameInfo _pickFeatured() {
    final pool = kGames.where((g) => g.id != 'daily').toList();
    if (widget.featuredGameId != null) {
      return pool.firstWhere((g) => g.id == widget.featuredGameId);
    }
    return pool[Random().nextInt(pool.length)];
  }

  Future<void> _loadEngagement() async {
    final loaded = await _progressStore.load();
    final isFirstLaunch = loaded.lastActiveDate == null;

    final result = applyDailyOpen(loaded, DateTime.now());
    await _progressStore.save(result.progress);
    if (!mounted) return;
    setState(() => _progress = result.progress);

    if (isFirstLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          );
        }
      });
    }
  }

  Future<void> _loadBests() async {
    for (final g in kGames) {
      _bests[g.id] = await _scoreStore.bestFor(g.id);
    }
    if (mounted) setState(() {});
  }

  void _openStreakSheet() => showDialog<void>(
        context: context,
        builder: (_) => StreakSheet(progress: _progress),
      );

  void _openDailyGift() {
    final today = DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DailyRewardScreen(
          progress: _progress,
          today: today,
          sound: _sound,
          onClaim: () => _claimDailyGift(today),
        ),
      ),
    );
  }

  Future<void> _claimDailyGift(DateTime today) async {
    if (!giftAvailable(_progress, today)) return;
    final updated = claimGift(_progress, today);
    await _progressStore.save(updated);
    if (!mounted) return;
    Navigator.of(context).pop();
    // The reward screen already played the collect animation + count-up, so the
    // hub pill just snaps to the new total (bump the epoch to skip re-animating).
    setState(() {
      _progress = updated;
      _coinEpoch++;
    });
  }

  /// Plays the fly-to-balance coin burst + shower toward the coin pill, after
  /// the next frame so the pill's key is laid out.
  void _collectCoins({required Offset from}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      playCoinBurst(
        context: context,
        from: from,
        toKey: _coinPillKey,
        sound: _sound,
      );
    });
  }

  void _openThemePicker() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ThemePickerScreen()),
      );

  Future<void> _openGame(GameInfo game) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => game.builder()));
    _loadBests();
    // Coins may have changed (e.g. the daily-challenge completion bonus).
    final p = await _progressStore.load();
    if (!mounted) return;
    final gained = p.coins - _progress.coins;
    setState(() => _progress = p); // coin pill counts up
    if (gained > 0) _collectCoins(from: _screenCenter());
  }

  Offset _screenCenter() {
    final s = MediaQuery.of(context).size;
    return Offset(s.width / 2, s.height * 0.42);
  }

  void _showAllGames() => setState(() => _tab = 1);

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
          child: Column(
            children: [
              Expanded(
                child: _tab == 0
                    ? _homePage(theme)
                    : const AllGamesScreen(embedded: true),
              ),
              _bottomNav(theme),
              if (!premium) const BannerAdBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homePage(GameTheme theme) {
    // The home content never scrolls. It renders at its natural size when it
    // fits, and scales down just enough to fit when the screen is short.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.clamp(0.0, 480.0);
        return Align(
          // Sit a little above centre so the title isn't pushed too far down.
          alignment: const Alignment(0, -0.35),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topArea(theme),
                    const SizedBox(height: 18),
                    _gamesHeader(theme),
                    const SizedBox(height: 10),
                    _featuredCard(theme, _featured),
                    const SizedBox(height: 10),
                    _dailyCard(theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- top: title, subtitle, stats, palette, gift ----------

  Widget _topArea(GameTheme theme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number Games',
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: theme.onBackground,
                    height: 1.05)),
            const SizedBox(height: 6),
            Text('Play, solve, and train your brain!',
                style: TextStyle(
                    fontSize: 15,
                    color: theme.onBackground.withValues(alpha: 0.8))),
            const SizedBox(height: 22),
            Row(
              children: [
                _statPill(const Text('🔥', style: TextStyle(fontSize: 22)),
                    Text('${_progress.streakCurrent} day', style: _statValueStyle),
                    'Streak', onTap: _openStreakSheet),
                const SizedBox(width: 12),
                _statPill(
                    const CoinIcon(size: 24),
                    AnimatedCoinCount(_progress.coins,
                        key: ValueKey(_coinEpoch), style: _statValueStyle),
                    'Coins',
                    pillKey: _coinPillKey),
              ],
            ),
          ],
        ),
        Positioned(top: 4, right: 0, child: _paletteButton(theme)),
        Positioned(top: 64, right: 4, child: _giftButton()),
      ],
    );
  }

  Widget _statPill(Widget icon, Widget value, String label,
      {VoidCallback? onTap, Key? pillKey}) {
    final pill = Container(
      key: pillKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              value,
              Text(label,
                  style: const TextStyle(fontSize: 12, color: _cardSub)),
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }

  Widget _paletteButton(GameTheme theme) {
    return Material(
      color: theme.scoreBox,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _openThemePicker,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.palette_outlined, color: theme.onBackground, size: 22),
        ),
      ),
    );
  }

  Widget _giftButton() {
    final available = giftAvailable(_progress, DateTime.now());
    return GestureDetector(
      onTap: _openDailyGift,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            key: _giftKey,
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                if (available)
                  BoxShadow(
                      color: kCoinGold.withValues(alpha: 0.65), blurRadius: 18),
              ],
            ),
            child: const Center(child: Text('🎁', style: TextStyle(fontSize: 30))),
          ),
          if (available)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D6D),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- games header + featured card ----------

  Widget _gamesHeader(GameTheme theme) {
    return Row(
      children: [
        Text('Games',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: theme.onBackground)),
        const Spacer(),
        GestureDetector(
          onTap: _showAllGames,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text('See all',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.onBackground.withValues(alpha: 0.85))),
              Icon(Icons.chevron_right,
                  size: 18, color: theme.onBackground.withValues(alpha: 0.85)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featuredCard(GameTheme theme, GameInfo game) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _miniIcon(game),
                  const SizedBox(height: 8),
                  Text(game.title,
                      style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: _cardTitle)),
                  Text(game.subtitle,
                      style: const TextStyle(fontSize: 11.5, color: _cardSub)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(game.bestText(_bests[game.id] ?? 0),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _accent)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _playButton(game),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _boardPreview(theme, game)),
          ],
        ),
      ),
    );
  }

  Widget _miniIcon(GameInfo game) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [game.accent, _darken(game.accent)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(game.icon, color: Colors.white, size: 21),
    );
  }

  // A slightly darker shade of [c], for the icon tile's gradient.
  Color _darken(Color c, [double amount = 0.14]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  Widget _playButton(GameInfo game) {
    return GestureDetector(
      onTap: () => _openGame(game),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFF53D9E)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFF53D9E).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Play Now',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            SizedBox(width: 6),
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  // A square snapshot of the featured game's board, matching whichever game
  // was picked for the highlight.
  Widget _boardPreview(GameTheme theme, GameInfo game) {
    final Widget board;
    switch (game.id) {
      case 'numbertap':
        board = _tapPreview();
        break;
      case 'numbersort':
        board = _sortPreview();
        break;
      case 'magicsquare':
        board = _magicPreview();
        break;
      case '2048':
      default:
        board = _board2048Preview(theme);
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AspectRatio(aspectRatio: 1, child: board),
    );
  }

  Widget _board2048Preview(GameTheme theme) {
    const sample = [
      [2, 4, 0, 0],
      [4, 8, 0, 0],
      [16, 32, 4, 0],
      [32, 128, 2, 0],
    ];
    return Column(
      children: [
        for (final row in sample)
          Expanded(
            child: Row(
              children: [
                for (final v in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2.5),
                      child: _previewTile(theme, v),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _previewTile(GameTheme theme, int value) {
    if (value == 0) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(7),
        ),
      );
    }
    final tc = theme.tileColors(value);
    return Container(
      decoration: BoxDecoration(
        color: tc.background,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Center(
        child: Text('$value',
            style: TextStyle(
                fontSize: value < 100 ? 14 : 11,
                fontWeight: FontWeight.w800,
                color: tc.text)),
      ),
    );
  }

  // Number Tap: a 4x4 grid of scattered numbers, the next ones to tap glowing.
  Widget _tapPreview() {
    const cells = [7, 1, 9, 2, 5, 3, 8, 4, 1, 6, 2, 9, 3, 5, 7, 4];
    const highlight = {1, 5, 8}; // indices shown as the "next" target
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < cells.length; i++)
          Container(
            decoration: BoxDecoration(
              gradient: highlight.contains(i)
                  ? const LinearGradient(
                      colors: [Color(0xFF7BE86B), Color(0xFF34C759)])
                  : null,
              color: highlight.contains(i) ? null : Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text('${cells[i]}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: highlight.contains(i)
                          ? Colors.white
                          : const Color(0xFF5B3DF5))),
            ),
          ),
      ],
    );
  }

  // Number Sort: columns of stacked colored blocks, one column still empty.
  Widget _sortPreview() {
    const cols = [
      [1, 3, 2],
      [2, 1, 3],
      [3, 2, 1],
      <int>[],
    ];
    const colors = {
      1: Color(0xFFFFB23F),
      2: Color(0xFFFF4D9D),
      3: Color(0xFF3FA3F0),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final col in cols)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final v in col)
                  Container(
                    height: 18,
                    margin: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: colors[v],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text('$v',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // Magic Square: the classic 3x3 grid where every line sums to 15.
  Widget _magicPreview() {
    const sample = [
      [8, 1, 6],
      [3, 5, 7],
      [4, 9, 2],
    ];
    return Column(
      children: [
        for (final row in sample)
          Expanded(
            child: Row(
              children: [
                for (final v in row)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3D2FF),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                        child: Text('$v',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5B2DA8))),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------- daily challenge card + bottom nav ----------

  Widget _dailyCard(GameTheme theme) {
    final daily = kGames.firstWhere((g) => g.id == 'daily');
    return GameCompactCard(
      game: daily,
      best: _bests[daily.id] ?? 0,
      onTap: () => _openGame(daily),
    );
  }

  Widget _bottomNav(GameTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: theme.scoreBox,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.glassStroke, width: 1),
        ),
        child: Row(
          children: [
            _navItem(theme, Icons.home_rounded, 'Home', 0),
            _navItem(theme, Icons.grid_view_rounded, 'All Games', 1),
          ],
        ),
      ),
    );
  }

  Color _getNavActiveColor(GameTheme theme) {
    switch (theme.id) {
      case 'neon':
        return const Color(0xFF00D4FF); // Neon cyan
      case 'ocean':
        return const Color(0xFF00E5FF); // Ocean cyan
      case 'forest':
        return const Color(0xFFAEEA00); // Lime green
      case 'candy':
        return const Color(0xFF7A2E5D); // Candy plum
      case 'sunset':
        return const Color(0xFFFFCA28); // Sunset yellow/orange
      case 'gold':
        return const Color(0xFFFFDF3D); // Gold
      case 'aurora':
      default:
        return const Color(0xFFFFD23F); // Vibrant gold/yellow
    }
  }

  Widget _navItem(GameTheme theme, IconData icon, String label, int index) {
    final active = _tab == index;
    final color = active ? _getNavActiveColor(theme) : theme.onBackground.withValues(alpha: 0.75);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
