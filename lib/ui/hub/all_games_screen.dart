import 'package:flutter/material.dart';

import '../../game/progress_store.dart';
import '../../game/score_store.dart';
import '../theme_controller.dart';
import 'game_registry.dart';

// The Daily hero keeps a fixed pink brand gradient across all themes, so the
// featured card stays recognizable however the background recolors.
const _heroGradient = [Color(0xFFFF7EB3), Color(0xFFFF6FA5), Color(0xFFC84BD6)];
const _heroButtonText = Color(0xFFC8336E);

/// Lists every game in the collection: the Daily Challenge as a featured hero
/// card, with the rest as frosted-glass cards that recolor with the theme.
/// Reached from the hub's "See all".
class AllGamesScreen extends StatefulWidget {
  /// When [embedded], the screen renders as a tab inside the hub: it drops its
  /// own Scaffold/background and the header's back button, since the hub shell
  /// already provides the gradient, safe area, and bottom nav.
  const AllGamesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AllGamesScreen> createState() => _AllGamesScreenState();
}

class _AllGamesScreenState extends State<AllGamesScreen> {
  final ScoreStore _store = ScoreStore();
  final ProgressStore _progressStore = ProgressStore();
  final Map<String, int> _bests = {};
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadBests();
    _loadStreak();
  }

  Future<void> _loadBests() async {
    for (final g in kGames) {
      _bests[g.id] = await _store.bestFor(g.id);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadStreak() async {
    final progress = await _progressStore.load();
    if (mounted) setState(() => _streak = progress.streakCurrent);
  }

  Future<void> _open(GameInfo game) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => game.builder()));
    _loadBests();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final daily = kGames.firstWhere((g) => g.id == 'daily');
    final others = kGames.where((g) => g.id != 'daily').toList();

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            _header(theme),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
                  _heroCard(theme, daily),
                  const SizedBox(height: 16),
                  for (final g in others) ...[
                    _glassCard(theme, g),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // As a hub tab, the shell already supplies the gradient, safe area, and
    // bottom nav, so just return the content.
    if (widget.embedded) return content;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.backgroundGradient,
          ),
        ),
        child: SafeArea(child: content),
      ),
    );
  }

  Widget _header(GameTheme theme) {
    return Padding(
      padding: widget.embedded
          ? const EdgeInsets.fromLTRB(20, 16, 20, 10)
          : const EdgeInsets.fromLTRB(8, 8, 20, 10),
      child: Row(
        children: [
          if (!widget.embedded)
            IconButton(
              icon: Icon(Icons.arrow_back, color: theme.onBackground),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          Text('All Games',
              style: TextStyle(
                  color: theme.onBackground,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const Spacer(),
          if (_streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: theme.scoreBox,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.glassStroke, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text('$_streak',
                      style: TextStyle(
                          color: theme.onBackground,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroCard(GameTheme theme, GameInfo game) {
    return GestureDetector(
      onTap: () => _open(game),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: _heroGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: _heroGradient[1].withValues(alpha: 0.4),
                blurRadius: 22,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -6,
              top: -10,
              child: Icon(game.icon,
                  size: 88, color: Colors.white.withValues(alpha: 0.18)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroBadge(),
                const SizedBox(height: 12),
                Text(game.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(game.subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13.5)),
                const SizedBox(height: 16),
                _heroPlayButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text('⭐ DAILY CHALLENGE',
          style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5)),
    );
  }

  Widget _heroPlayButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, color: _heroButtonText, size: 22),
          SizedBox(width: 6),
          Text('Play Now',
              style: TextStyle(
                  color: _heroButtonText,
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _glassCard(GameTheme theme, GameInfo game) {
    return GestureDetector(
      onTap: () => _open(game),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: theme.scoreBox,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.glassStroke, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: game.accent.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(15),
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
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: theme.onBackground)),
                  Text(game.subtitle,
                      style: TextStyle(fontSize: 12, color: theme.scoreLabel)),
                  const SizedBox(height: 3),
                  Text('👑 ${game.bestText(_bests[game.id] ?? 0)}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: theme.onBackground.withValues(alpha: 0.9))),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.onBackground.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
