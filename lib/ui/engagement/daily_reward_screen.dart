import 'dart:async';

import 'package:flutter/material.dart';

import '../../game/daily_engagement.dart';
import '../../game/reward_schedule.dart';
import '../../game/sound_service.dart';
import '../theme_controller.dart';
import 'animated_coin_count.dart';
import 'coin_burst.dart';
import 'engagement_style.dart';

// Brand-constant accents (read as gold/green on every theme).
const _giftGradient = [Color(0xFFFFE27A), Color(0xFFFFB300)];
const _claimedGreen = Color(0xFF7CFFB0);

/// The Daily Rewards screen — a "tap-to-open gift" in the app's theme. Tapping
/// the wrapped gift reveals the day's coins, which fly into the balance pill
/// (count-up + coin-shower sound) before the claim is finalized.
class DailyRewardScreen extends StatefulWidget {
  final PlayerProgress progress;
  final DateTime today;
  final VoidCallback onClaim;
  final SoundService sound;

  const DailyRewardScreen({
    super.key,
    required this.progress,
    required this.today,
    required this.onClaim,
    required this.sound,
  });

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen> {
  final GlobalKey _coinKey = GlobalKey();
  final GlobalKey _giftKey = GlobalKey();

  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _revealing = false;
  int? _displayCoins; // overrides the header balance during the reveal

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    if (mounted) setState(() => _timeLeft = nextMidnight.difference(now));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Opens the gift: reveal the amount, fly coins into the balance with the
  /// shower sound, then finalize the claim (which saves and pops).
  Future<void> _reveal(int reward) async {
    if (_revealing) return;
    setState(() {
      _revealing = true;
      _displayCoins = widget.progress.coins + reward; // header counts up
    });
    final box = _giftKey.currentContext?.findRenderObject() as RenderBox?;
    final size = MediaQuery.of(context).size;
    final from = box != null
        ? box.localToGlobal(box.size.center(Offset.zero))
        : Offset(size.width / 2, size.height / 2);
    await playCoinBurst(
        context: context, from: from, toKey: _coinKey, sound: widget.sound);
    if (mounted) widget.onClaim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final available = giftAvailable(widget.progress, widget.today);
    final day = giftDayFor(widget.progress.streakCurrent);
    final reward = giftCoins(day) + milestoneBonus(widget.progress.streakCurrent);
    final claimedThrough = available ? day - 1 : day;

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
              _header(theme),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _giftCard(theme, available, reward),
                        const SizedBox(height: 22),
                        _hints(theme, available, day, reward),
                        const SizedBox(height: 22),
                        _dots(theme, day, claimedThrough, available),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: _streakReminder(theme),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: _button(theme, available, reward),
              ),
              _footer(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(GameTheme theme) {
    final c = theme.onBackground;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.30)),
              ),
              child: Icon(Icons.arrow_back_rounded, color: c, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Rewards',
                    style: TextStyle(
                        color: c, fontSize: 20, fontWeight: FontWeight.w900)),
                Text('Come back every day and earn more!',
                    style: TextStyle(
                        color: c.withValues(alpha: 0.7), fontSize: 12)),
              ],
            ),
          ),
          Container(
            key: _coinKey,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinIcon(size: 18),
                const SizedBox(width: 6),
                AnimatedCoinCount(
                  _displayCoins ?? widget.progress.coins,
                  style: TextStyle(
                      color: c, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _giftCard(GameTheme theme, bool available, int reward) {
    final opened = _revealing || !available;
    final card = Container(
      key: _giftKey,
      width: 200,
      height: 230,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _giftGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: kCoinGold.withValues(alpha: available ? 0.55 : 0.25),
              blurRadius: 34,
              offset: const Offset(0, 14)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ribbon cross (hidden once opened).
          if (!opened)
            const Positioned.fill(
              child: _Ribbon(),
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(opened ? '🎁' : '🎀',
                  style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 4),
              if (_revealing)
                Text('+$reward',
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7A4A00)))
              else if (!opened)
                const Text('?',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF7A4A00))),
            ],
          ),
        ],
      ),
    );

    // Tappable only when there's a gift to open.
    if (!available || _revealing) {
      return Opacity(opacity: opened && !available ? 0.85 : 1, child: card);
    }
    return GestureDetector(onTap: () => _reveal(reward), child: card);
  }

  Widget _hints(GameTheme theme, bool available, int day, int reward) {
    final c = theme.onBackground;
    if (_revealing) {
      return Text('+$reward coins!',
          style: const TextStyle(
              color: Color(0xFFFFE27A),
              fontSize: 18,
              fontWeight: FontWeight.w900));
    }
    if (!available) {
      return Text('Next reward in ${_fmt(_timeLeft)}',
          style: TextStyle(
              color: c.withValues(alpha: 0.85),
              fontSize: 15,
              fontWeight: FontWeight.w800));
    }
    return Column(
      children: [
        Text('Tap to open Day $day',
            style:
                TextStyle(color: c, fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          '${widget.progress.streakCurrent}-day streak · today\'s gift is +$reward coins',
          textAlign: TextAlign.center,
          style: TextStyle(color: c.withValues(alpha: 0.75), fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _dots(GameTheme theme, int day, int claimedThrough, bool available) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var n = 1; n <= 7; n++) ...[
          if (n > 1) const SizedBox(width: 8),
          _dot(theme, n, day, claimedThrough, available),
        ],
      ],
    );
  }

  Widget _dot(
      GameTheme theme, int n, int day, int claimedThrough, bool available) {
    final claimed = n <= claimedThrough;
    final today = available && n == day;
    if (today) {
      return Container(
        width: 26,
        height: 9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: claimed ? _claimedGreen : Colors.white.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _streakReminder(GameTheme theme) {
    final c = theme.onBackground;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kFlame.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keep your streak alive!',
                    style: TextStyle(
                        color: c, fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text("Don't miss a day to maximize your rewards.",
                    style: TextStyle(
                        color: c.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(GameTheme theme, bool available, int reward) {
    if (_revealing) {
      return const SizedBox(height: 56); // reserve space while coins fly
    }
    if (!available) {
      return Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Text('Come back tomorrow',
            style: TextStyle(
                color: theme.onBackground.withValues(alpha: 0.6),
                fontSize: 15,
                fontWeight: FontWeight.w800)),
      );
    }
    return GestureDetector(
      onTap: () => _reveal(reward),
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(colors: _giftGradient),
          boxShadow: [
            BoxShadow(
                color: kCoinGold.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        child: const Text('Tap to Reveal 🎁',
            style: TextStyle(
                color: Color(0xFF5A3A00),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3)),
      ),
    );
  }

  Widget _footer(GameTheme theme) {
    final c = theme.onBackground.withValues(alpha: 0.5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_outlined, color: c, size: 13),
          const SizedBox(width: 6),
          Text('Rewards reset daily at midnight',
              style: TextStyle(
                  color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// The white ribbon cross on the wrapped gift.
class _Ribbon extends StatelessWidget {
  const _Ribbon();

  @override
  Widget build(BuildContext context) {
    final band = Colors.white.withValues(alpha: 0.45);
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(width: 26, color: band),
        ),
        Align(
          alignment: Alignment.center,
          child: Container(height: 26, color: band),
        ),
      ],
    );
  }
}
