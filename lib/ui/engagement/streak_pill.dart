import 'package:flutter/material.dart';

import '../theme_controller.dart';
import 'engagement_style.dart';

/// A pill showing the current daily streak; tapping opens the streak sheet.
class StreakPill extends StatelessWidget {
  final int streak;
  final VoidCallback onTap;

  const StreakPill({super.key, required this.streak, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: pillDecoration(theme),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, size: 18, color: kFlame),
            const SizedBox(width: 5),
            Text(
              '$streak',
              style: TextStyle(
                color: theme.onBackground,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'day',
              style: TextStyle(
                color: theme.scoreLabel,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
