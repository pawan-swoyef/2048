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

/// Asks a returning player whether to continue their saved game. Resolves to
/// true to resume, false to start fresh. Dismissing defaults to resuming so a
/// stray tap never throws away progress. Styled with a gold "game in progress"
/// hero band, matching the Daily Challenge chrome.
Future<bool> confirmResume(BuildContext context) async {
  final theme = ThemeScope.of(context);
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: theme.dialogCard,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hero band: gold→orange gradient with a faint controller glyph.
          Container(
            width: double.infinity,
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFC12E), Color(0xFFFF6A3D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -6,
                  top: -14,
                  child: Text('🎮',
                      style: TextStyle(
                          fontSize: 78,
                          color: Colors.white.withValues(alpha: 0.22))),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⭐ GAME IN PROGRESS',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6)),
                    SizedBox(height: 2),
                    Text('Welcome back!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your last game is saved. Want to keep playing?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GhostButton(
                        label: 'New Game',
                        onPressed: () => Navigator.pop(context, false)),
                    const SizedBox(width: 10),
                    PrimaryButton(
                        label: 'Resume',
                        onPressed: () => Navigator.pop(context, true)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? true;
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
