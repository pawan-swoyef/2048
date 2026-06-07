import 'package:flutter/material.dart';

import 'game_buttons.dart';
import 'theme_controller.dart';

/// Asks the player to confirm starting a new game (losing current progress).
/// Resolves to true if they confirm.
Future<bool> confirmNewGame(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _GameDialog(
      title: 'Start a new game?',
      body: const Text(
        'Your current game will be lost. Your best score stays saved.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
      ),
      actions: [
        GhostButton(label: 'Cancel', onPressed: () => Navigator.pop(context, false)),
        PrimaryButton(label: 'New Game', onPressed: () => Navigator.pop(context, true)),
      ],
    ),
  );
  return result ?? false;
}

/// Shows the "How to Play" rules.
Future<void> showHowToPlay(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => _GameDialog(
      title: 'How to Play',
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Rule('Swipe ← ↑ → ↓ to move all tiles.'),
          _Rule('Two tiles with the same number merge into one.'),
          _Rule('Each merge adds to your score.'),
          _Rule('Reach the 2048 tile to win — then keep going!'),
        ],
      ),
      actions: [
        PrimaryButton(label: 'Got it', onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}

class _Rule extends StatelessWidget {
  final String text;
  const _Rule(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: Colors.white, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared styled dialog container (rounded cream card).
class _GameDialog extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;

  const _GameDialog({
    required this.title,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ThemeScope.of(context).dialogCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            body,
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
