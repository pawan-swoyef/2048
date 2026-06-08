import 'package:flutter/material.dart';

import '../../game/daily_engagement.dart';
import '../theme_controller.dart';
import 'engagement_style.dart';

/// Bottom sheet / dialog body showing streak details and milestones.
class StreakSheet extends StatelessWidget {
  final PlayerProgress progress;

  const StreakSheet({super.key, required this.progress});

  static const _milestones = [3, 7, 14, 30];

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final nextMilestone =
        _milestones.firstWhere((m) => m > progress.streakCurrent, orElse: () => _milestones.last);
    final progressFrac = (progress.streakCurrent / nextMilestone).clamp(0.0, 1.0);

    return Center(
      child: Container(
        width: 320,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          color: theme.dialogCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 14)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔥', style: TextStyle(fontSize: 52, shadows: [
              Shadow(color: kFlame.withValues(alpha: 0.9), blurRadius: 16),
            ])),
            Text('${progress.streakCurrent}',
                style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
            Text('day streak · best: ${progress.streakLongest}',
                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progressFrac,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                valueColor: const AlwaysStoppedAnimation(kFlame),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final m in _milestones)
                  Text('$m',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: progress.streakCurrent >= m ? const Color(0xFFFFD23F) : const Color(0xB0FFFFFF),
                      )),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('❄️ ', style: TextStyle(fontSize: 13)),
                  Flexible(
                    child: Text(
                      progress.streakFreezes > 0
                          ? 'Streak Freeze ready — saves you if you miss a day'
                          : 'Streak Freeze used — back next 7-day cycle',
                      style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
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
}
