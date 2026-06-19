import 'package:flutter/material.dart';

import '../game_screen.dart';
import '../numbertap/number_tap_screen.dart';

/// Describes one game in the collection, shown as a card on the hub.
class GameInfo {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  /// Builds the game's screen when its card is tapped.
  final Widget Function() builder;

  /// Formats the stored best score for the hub card. Defaults to `Best: <n>`.
  final String Function(int best)? bestLabel;

  const GameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.builder,
    this.bestLabel,
  });

  String bestText(int best) => bestLabel?.call(best) ?? 'Best: $best';
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
  GameInfo(
    id: 'numbertap',
    title: 'Number Tap',
    subtitle: 'Tap 1–25, beat the clock',
    icon: Icons.touch_app_rounded,
    accent: const Color(0xFF4FC3F7),
    builder: () => const NumberTapScreen(),
    bestLabel: (deci) =>
        deci <= 0 ? 'Best: —' : 'Best: ${(deci / 10).toStringAsFixed(1)}s',
  ),
];
