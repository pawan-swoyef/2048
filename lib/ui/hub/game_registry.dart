import 'package:flutter/material.dart';

import '../game_screen.dart';

/// Describes one game in the collection, shown as a card on the hub.
class GameInfo {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  /// Builds the game's screen when its card is tapped.
  final Widget Function() builder;

  const GameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.builder,
  });
}

/// The games available in the collection. New games append here.
final List<GameInfo> kGames = [
  GameInfo(
    id: '2048',
    title: '2048',
    subtitle: 'Classic merge puzzle',
    icon: Icons.grid_view_rounded,
    accent: const Color(0xFFFFC12E),
    builder: () => const GameScreen(),
  ),
];
