import 'package:flutter/material.dart';

import '../../game/daily_engagement.dart';
import '../../game/progress_store.dart';
import '../../game/score_store.dart';
import '../engagement/daily_gift_dialog.dart';
import '../engagement/engagement_style.dart';
import '../engagement/reward_toast.dart';
import '../engagement/streak_sheet.dart';
import '../theme_controller.dart';
import '../theme_picker.dart';
import 'game_registry.dart';

// Text colors used on the white cards (kept readable across themes).
const _cardTitle = Color(0xFF241139);
const _cardSub = Color(0xFF8A7CA8);
const _accent = Color(0xFF6A2DBF);
const _navActive = Color(0xFFFF5C8A);

/// The home hub: a polished landing screen with the engagement stats, a
/// featured game, and a bottom nav. The app opens here.
class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  final ProgressStore _progressStore = ProgressStore();
  final ScoreStore _scoreStore = ScoreStore();

  PlayerProgress _progress = const PlayerProgress();
  final Map<String, int> _bests = {};

  @override
  void initState() {
    super.initState();
    _loadEngagement();
    _loadBests();
  }

  Future<void> _loadEngagement() async {
    final loaded = await _progressStore.load();
    final result = applyDailyOpen(loaded, DateTime.now());
    await _progressStore.save(result.progress);
    if (!mounted) return;
    setState(() => _progress = result.progress);
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

  void _openThemePicker() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ThemePickerScreen()),
      );

  Future<void> _openGame(GameInfo game) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => game.builder()));
    _loadBests();
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _topArea(theme),
                            const SizedBox(height: 26),
                            _gamesHeader(theme),
                            const SizedBox(height: 12),
                            _featuredCard(theme, kGames.first),
                            for (final g in kGames.skip(1)) ...[
                              const SizedBox(height: 12),
                              _compactCard(theme, g),
                            ],
                            const SizedBox(height: 20),
                            _whyCard(theme),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _bottomNav(theme),
            ],
          ),
        ),
      ),
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
                    '${_progress.streakCurrent} day', 'Streak',
                    onTap: _openStreakSheet),
                const SizedBox(width: 12),
                _statPill(const CoinIcon(size: 24), '${_progress.coins}', 'Coins'),
              ],
            ),
          ],
        ),
        Positioned(top: 4, right: 0, child: _paletteButton(theme)),
        Positioned(top: 64, right: 4, child: _giftButton()),
      ],
    );
  }

  Widget _statPill(Widget icon, String value, String label, {VoidCallback? onTap}) {
    final pill = Container(
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
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: _cardTitle)),
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
        Row(
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
      ],
    );
  }

  Widget _featuredCard(GameTheme theme, GameInfo game) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 22,
              offset: const Offset(0, 10)),
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
                  _miniIcon(theme),
                  const SizedBox(height: 14),
                  Text(game.title,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: _cardTitle)),
                  Text(game.subtitle,
                      style: const TextStyle(fontSize: 13.5, color: _cardSub)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Best: ${_bests[game.id] ?? 0}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _accent)),
                      const SizedBox(width: 6),
                      const Text('👑', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _playButton(game),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: _boardPreview(theme)),
          ],
        ),
      ),
    );
  }

  Widget _compactCard(GameTheme theme, GameInfo game) {
    return GestureDetector(
      onTap: () => _openGame(game),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: game.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(game.icon, color: game.accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(game.title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _cardTitle)),
                  Text(game.subtitle,
                      style: const TextStyle(fontSize: 12.5, color: _cardSub)),
                  const SizedBox(height: 2),
                  Text(game.bestText(_bests[game.id] ?? 0),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800, color: _accent)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _cardSub),
          ],
        ),
      ),
    );
  }

  Widget _miniIcon(GameTheme theme) {
    const values = [2, 0, 4, 8];
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B5CFF), Color(0xFF5B3DF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final v in values)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Center(
                child: Text('$v',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5B3DF5))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _playButton(GameInfo game) {
    return GestureDetector(
      onTap: () => _openGame(game),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFFF53D9E)],
          ),
          borderRadius: BorderRadius.circular(14),
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
                    fontSize: 15)),
            SizedBox(width: 8),
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _boardPreview(GameTheme theme) {
    const sample = [
      [2, 4, 0, 0],
      [4, 8, 0, 0],
      [16, 32, 4, 0],
      [32, 128, 2, 0],
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Column(
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
        ),
      ),
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

  // ---------- why-play card + bottom nav ----------

  Widget _whyCard(GameTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.glassStroke, width: 1),
      ),
      child: Column(
        children: [
          Text('Why play number games?',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: theme.onBackground)),
          const SizedBox(height: 16),
          Row(
            children: [
              _why(theme, '🧠', 'Improve', 'your brain'),
              _whyDivider(theme),
              _why(theme, '⚡', 'Sharpen', 'your skills'),
              _whyDivider(theme),
              _why(theme, '🎯', 'Challenge', 'yourself'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _why(GameTheme theme, String emoji, String l1, String l2) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(l1,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: theme.onBackground)),
          Text(l2,
              style: TextStyle(
                  fontSize: 13,
                  color: theme.onBackground.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _whyDivider(GameTheme theme) => Container(
        width: 1,
        height: 42,
        color: theme.onBackground.withValues(alpha: 0.18),
      );

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
            _navItem(theme, Icons.home_rounded, 'Home', active: true),
            _navItem(theme, Icons.emoji_events_outlined, 'Stats'),
            _navItem(theme, Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(GameTheme theme, IconData icon, String label,
      {bool active = false}) {
    final color = active ? _navActive : theme.onBackground.withValues(alpha: 0.6);
    return Expanded(
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
    );
  }
}
