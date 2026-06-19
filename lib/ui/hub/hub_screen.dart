import 'package:flutter/material.dart';

import '../../game/daily_engagement.dart';
import '../../game/progress_store.dart';
import '../../game/score_store.dart';
import '../engagement/coin_pill.dart';
import '../engagement/daily_gift_button.dart';
import '../engagement/daily_gift_dialog.dart';
import '../engagement/reward_toast.dart';
import '../engagement/streak_pill.dart';
import '../engagement/streak_sheet.dart';
import '../game_buttons.dart';
import '../theme_controller.dart';
import '../theme_picker.dart';
import 'game_registry.dart';

/// The home hub: a themed grid of game cards plus the app-level engagement row
/// (daily streak, coins, daily gift). The app opens here.
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

  void _openThemePicker() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ThemePickerScreen()),
    );
  }

  Future<void> _openGame(GameInfo game) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => game.builder()),
    );
    // Best scores may have changed while playing.
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Number Games',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: theme.onBackground,
                          ),
                        ),
                        const Spacer(),
                        IconActionButton(
                          icon: Icons.palette_outlined,
                          onPressed: _openThemePicker,
                        ),
                      ],
                    ),
                    if (_progress.streakCurrent > 0) ...[
                      const SizedBox(height: 16),
                      _statRow(),
                    ],
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.92,
                        children: [for (final g in kGames) _card(theme, g)],
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _card(GameTheme theme, GameInfo game) {
    return Material(
      color: theme.scoreBox,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openGame(game),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.glassStroke, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(game.icon, color: game.accent, size: 40),
              const Spacer(),
              Text(
                game.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: theme.onBackground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                game.subtitle,
                style: TextStyle(fontSize: 12.5, color: theme.scoreLabel),
              ),
              const SizedBox(height: 6),
              Text(
                'Best: ${_bests[game.id] ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.onBackground.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
