import 'package:flutter/material.dart';

import 'game_buttons.dart';
import 'tile_style.dart';

/// Overlay shown over the board when the player reaches 2048.
class WinOverlay extends StatelessWidget {
  final VoidCallback onKeepGoing;
  final VoidCallback onNewGame;

  const WinOverlay({
    super.key,
    required this.onKeepGoing,
    required this.onNewGame,
  });

  @override
  Widget build(BuildContext context) {
    return _BoardOverlay(
      title: 'You Win! 🎉',
      titleColor: GameColors.win,
      message: 'You reached 2048. Keep going for a higher score?',
      actions: [
        GhostButton(label: 'New Game', onPressed: onNewGame),
        PrimaryButton(label: 'Keep Going', onPressed: onKeepGoing),
      ],
    );
  }
}

/// Overlay shown over the board when no moves remain.
class GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onTryAgain;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return _BoardOverlay(
      title: 'Game Over!',
      titleColor: GameColors.darkText,
      message: 'No more moves. Final score: $score',
      actions: [
        PrimaryButton(label: 'Try Again', onPressed: onTryAgain),
      ],
    );
  }
}

class _BoardOverlay extends StatelessWidget {
  final String title;
  final Color titleColor;
  final String message;
  final List<Widget> actions;

  const _BoardOverlay({
    required this.title,
    required this.titleColor,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        decoration: BoxDecoration(
          color: GameColors.overlayScrim,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: GameColors.darkText,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  actions[i],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
