import 'package:flutter/material.dart';

import '../../game/daily_engagement.dart';
import '../../game/reward_schedule.dart';
import '../theme_controller.dart';
import 'engagement_style.dart';

/// The daily-gift claim dialog: today's reward plus a 7-day calendar.
class DailyGiftDialog extends StatelessWidget {
  final PlayerProgress progress;
  final DateTime today;
  final VoidCallback onClaim;

  const DailyGiftDialog({
    super.key,
    required this.progress,
    required this.today,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final available = giftAvailable(progress, today);
    final day = giftDayFor(progress.streakCurrent);
    final reward =
        giftCoins(giftDayFor(progress.streakCurrent)) + milestoneBonus(progress.streakCurrent);
    // Days strictly before today's are already claimed; today's too if claimed.
    final claimedThrough = available ? day - 1 : day;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 320,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            color: theme.dialogCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Day $day Reward 🎉',
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('${progress.streakCurrent}-day streak — keep going!',
                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12.5)),
              const SizedBox(height: 14),
              Text('🎁', style: TextStyle(fontSize: 46, shadows: [
                Shadow(color: kCoinGold.withValues(alpha: 0.8), blurRadius: 16),
              ])),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CoinIcon(size: 22),
                  const SizedBox(width: 7),
                  Text('+$reward',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 16),
              _calendar(claimedThrough, day, available),
              const SizedBox(height: 18),
              if (available)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.primaryButtonText,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onClaim,
                    child: const Text('Claim Reward',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                )
              else
                const Text('Come back tomorrow for your next gift!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calendar(int claimedThrough, int currentDay, bool available) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      childAspectRatio: 0.92,
      children: [
        for (var n = 1; n <= 7; n++)
          _DayCell(
            day: n,
            coins: giftCoins(n),
            isClaimed: n <= claimedThrough,
            isToday: available && n == currentDay,
            isBig: n == 7,
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int coins;
  final bool isClaimed;
  final bool isToday;
  final bool isBig;

  const _DayCell({
    required this.day,
    required this.coins,
    required this.isClaimed,
    required this.isToday,
    required this.isBig,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    Color bg = Colors.white.withValues(alpha: 0.10);
    Color border = Colors.white.withValues(alpha: 0.18);
    Color fg = Colors.white;
    if (isBig) {
      bg = const Color(0xFFFFD23F);
      border = const Color(0xFFFFD23F);
      fg = const Color(0xFF5A3A00);
    }
    if (isToday) {
      bg = Colors.white;
      border = Colors.white;
      fg = theme.primaryButtonText;
    }
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
        boxShadow: isToday
            ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 12)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('D$day',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: fg.withValues(alpha: 0.8))),
          const SizedBox(height: 2),
          if (isClaimed)
            const Icon(Icons.check_circle, size: 15, color: Color(0xFF7CFFB0))
          else
            Icon(Icons.star_rounded, size: 14, color: isBig ? fg : kCoinGold),
          const SizedBox(height: 1),
          Text('$coins', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
        ],
      ),
    );
  }
}
