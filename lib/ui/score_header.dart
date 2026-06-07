import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// The top row: the "2048" logo and the Score / Best boxes, styled by theme.
class ScoreHeader extends StatelessWidget {
  final int score;
  final int best;

  const ScoreHeader({super.key, required this.score, required this.best});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '2048',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w800,
            color: theme.onBackground,
            letterSpacing: 1,
            shadows: const [
              Shadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 3)),
            ],
          ),
        ),
        Row(
          children: [
            _ScoreBox(label: 'SCORE', value: score, theme: theme),
            const SizedBox(width: 8),
            _ScoreBox(label: 'BEST', value: best, theme: theme),
          ],
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int value;
  final GameTheme theme;

  const _ScoreBox({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scoreBox,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.glassStroke, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: theme.scoreLabel,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}
