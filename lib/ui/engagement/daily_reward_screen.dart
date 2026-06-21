import 'dart:async';
import 'package:flutter/material.dart';

import '../../game/daily_engagement.dart';
import '../../game/reward_schedule.dart';
import '../theme_controller.dart';
import 'coin_pill.dart';
import 'engagement_style.dart';

// The featured card's beautiful gradient.
const _featuredGradient = [
  Color(0xFF4F1CA6),
  Color(0xFF9F28B4),
  Color(0xFFE2387B),
  Color(0xFFF9663E),
];

// Dark background gradient matching the mockup.
const _backgroundGradient = [
  Color(0xFF0C0926),
  Color(0xFF140E34),
];

// Active button gradient.
const _buttonGradient = [
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
];

class DailyRewardScreen extends StatefulWidget {
  final PlayerProgress progress;
  final DateTime today;
  final VoidCallback onClaim;

  const DailyRewardScreen({
    super.key,
    required this.progress,
    required this.today,
    required this.onClaim,
  });

  @override
  State<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends State<DailyRewardScreen> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _timeLeft = nextMidnight.difference(now);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          final nextMidnight = DateTime(now.year, now.month, now.day + 1);
          _timeLeft = nextMidnight.difference(now);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    _featuredCard(available, day, reward),
                    const SizedBox(height: 24),
                    _thisWeekHeader(available),
                    const SizedBox(height: 14),
                    _weekStripSection(day, claimedThrough, available),
                    const SizedBox(height: 24),
                    _streakReminder(),
                  ],
                ),
              ),
              _bottomAction(available, reward),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Rewards',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Come back every day and earn more!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CoinIcon(size: 20),
                const SizedBox(width: 6),
                Text(
                  '${widget.progress.coins}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuredCard(bool available, int day, int reward) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: _featuredGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9F28B4).withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFD23F), size: 14),
                const SizedBox(width: 6),
                Text(
                  available ? 'DAY $day • READY' : 'DAY $day • CLAIMED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/gift_box.png',
                  width: 125,
                  height: 125,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE27A), Color(0xFFFFB300)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.star_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '+$reward',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(text: '${widget.progress.streakCurrent}-day streak — '),
                const TextSpan(
                  text: 'keep it going!',
                  style: TextStyle(
                    color: Color(0xFFFFD23F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thisWeekHeader(bool available) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This week',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              available
                  ? 'Claim reward now!'
                  : 'Next reward in ${_formatDuration(_timeLeft)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _weekStripSection(int currentDay, int claimedThrough, bool available) {
    const cardW = 64.0;
    const gap = 10.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var n = 1; n <= 7; n++) ...[
                  _dayCard(n, currentDay, claimedThrough, available, cardW),
                  if (n < 7) const SizedBox(width: gap),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var n = 1; n <= 7; n++) ...[
                  Container(
                    width: cardW,
                    alignment: Alignment.center,
                    child: _timelineDot(n, currentDay, claimedThrough, available),
                  ),
                  if (n < 7) _timelineLine(n, currentDay, claimedThrough, available, gap),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCard(
    int n,
    int currentDay,
    int claimedThrough,
    bool available,
    double w,
  ) {
    final isClaimed = n <= claimedThrough;
    final isToday = available && n == currentDay;
    final isLocked = n > currentDay;

    Color bg;
    Border? border;
    Color textCol;
    Widget icon;

    if (isToday) {
      bg = Colors.white;
      border = null;
      textCol = const Color(0xFF1E1B4B);
      icon = Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF8B5CF6),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
      );
    } else if (isClaimed) {
      bg = Colors.white.withOpacity(0.08);
      border = Border.all(color: Colors.white.withOpacity(0.12), width: 1);
      textCol = Colors.white.withOpacity(0.5);
      icon = Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF8B5CF6),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
      );
    } else {
      // Locked future day
      bg = Colors.white.withOpacity(0.04);
      border = Border.all(color: Colors.white.withOpacity(0.08), width: 1);
      textCol = Colors.white.withOpacity(0.35);
      icon = Icon(
        Icons.lock_outline_rounded,
        color: Colors.white.withOpacity(0.35),
        size: 20,
      );
    }

    final coins = giftCoins(n);

    return Container(
      width: w,
      height: 96,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: border,
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'DAY $n',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textCol.withOpacity(isToday ? 0.7 : 0.8),
            ),
          ),
          const SizedBox(height: 8),
          icon,
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$coins',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: textCol,
                ),
              ),
              const SizedBox(width: 3),
              CoinIcon(size: 11),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineDot(int n, int currentDay, int claimedThrough, bool available) {
    final isCompletedOrToday = n <= currentDay;
    final dotColor = isCompletedOrToday
        ? const Color(0xFFEC4899)
        : Colors.white.withOpacity(0.2);

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: dotColor,
        shape: BoxShape.circle,
        boxShadow: isCompletedOrToday
            ? [
                BoxShadow(
                  color: const Color(0xFFEC4899).withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
    );
  }

  Widget _timelineLine(int n, int currentDay, int claimedThrough, bool available, double w) {
    final isActive = n < currentDay;
    final lineColor = isActive
        ? const Color(0xFFEC4899)
        : Colors.white.withOpacity(0.12);

    return Container(
      width: w,
      height: 2.5,
      color: lineColor,
    );
  }

  Widget _streakReminder() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A3D).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep your streak alive!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Don't miss a day to maximize your rewards.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomAction(bool available, int reward) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: available
          ? Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: _buttonGradient,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC4899).withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: widget.onClaim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const SizedBox(width: 8),
                    const Text('🎁', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'Claim +$reward Reward',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('✨', style: TextStyle(fontSize: 16, color: Colors.white70)),
                  ],
                ),
              ),
            )
          : Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
              ),
              child: Center(
                child: Text(
                  'Come back tomorrow',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Colors.white.withOpacity(0.4),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            'Rewards reset daily at midnight',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
