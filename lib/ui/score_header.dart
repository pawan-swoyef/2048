import 'package:flutter/material.dart';

import 'tile_style.dart';

/// The top row: the "2048" logo badge and the Score / Best boxes.
class ScoreHeader extends StatelessWidget {
  final int score;
  final int best;

  const ScoreHeader({super.key, required this.score, required this.best});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _logo(),
        Row(
          children: [
            _ScoreBox(label: 'SCORE', value: score),
            const SizedBox(width: 8),
            _ScoreBox(label: 'BEST', value: best),
          ],
        ),
      ],
    );
  }

  Widget _logo() {
    return const Text(
      '2048',
      style: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 1,
        shadows: [
          Shadow(color: Color(0x80000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GameColors.scoreBox,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.glassStroke, width: 1.2),
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: GameColors.scoreLabel,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: GameColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}
