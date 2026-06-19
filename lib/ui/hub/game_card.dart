import 'package:flutter/material.dart';

import 'game_registry.dart';

const _cardTitle = Color(0xFF241139);
const _cardSub = Color(0xFF8A7CA8);
const _accent = Color(0xFF6A2DBF);

/// A compact white card for a game, used on the All Games list.
class GameCompactCard extends StatelessWidget {
  final GameInfo game;
  final int best;
  final VoidCallback onTap;

  const GameCompactCard({
    super.key,
    required this.game,
    required this.best,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: game.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(game.icon, color: game.accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(game.title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _cardTitle)),
                  Text(game.subtitle,
                      style: const TextStyle(fontSize: 12.5, color: _cardSub)),
                  const SizedBox(height: 2),
                  Text(game.bestText(best),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _accent)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _cardSub),
          ],
        ),
      ),
    );
  }
}
