import 'package:flutter/material.dart';

/// Background and number color for a tile of a given value.
class TileColors {
  final Color background;
  final Color text;
  const TileColors(this.background, this.text);
}

/// A complete visual theme for the game: background gradient, board surfaces,
/// tile colors, and UI accent colors.
class GameTheme {
  final String id;
  final String name;
  final bool isPremium;

  final List<Color> backgroundGradient;
  final Map<int, TileColors> _tiles;

  final Color boardBackground;
  final Color emptyCell;
  final Color glassStroke;
  final Color onBackground; // title / tagline / hint text over the gradient
  final Color scoreBox;
  final Color scoreLabel;
  final Color primaryButton;
  final Color primaryButtonText;
  final Color ghostButton;
  final Color dialogCard;
  final Color overlayScrim;
  final Color win;

  const GameTheme({
    required this.id,
    required this.name,
    required this.isPremium,
    required this.backgroundGradient,
    required Map<int, TileColors> tiles,
    required this.primaryButtonText,
    required this.dialogCard,
    this.boardBackground = const Color(0x24FFFFFF),
    this.emptyCell = const Color(0x1AFFFFFF),
    this.glassStroke = const Color(0x59FFFFFF),
    this.onBackground = Colors.white,
    this.scoreBox = const Color(0x2EFFFFFF),
    this.scoreLabel = const Color(0xCCFFFFFF),
    this.primaryButton = Colors.white,
    this.ghostButton = const Color(0x38FFFFFF),
    this.overlayScrim = const Color(0xCC1A1030),
    this.win = const Color(0xFFFFD23F),
  }) : _tiles = tiles;

  /// Colors for [value]; values above 2048 reuse the 2048 styling.
  TileColors tileColors(int value) => _tiles[value] ?? _tiles[2048]!;

  /// Font size for a tile number, scaled down for longer numbers.
  static double tileFontSize(int value, double size) {
    if (value < 100) return size * 0.45;
    if (value < 1000) return size * 0.38;
    return size * 0.30;
  }
}

const Color _w = Colors.white;

/// All themes. The first (Aurora) is free; the rest require the subscription.
const List<GameTheme> kThemes = [
  GameTheme(
    id: 'aurora',
    name: 'Aurora',
    isPremium: false,
    backgroundGradient: [Color(0xFF5B3DF5), Color(0xFFA23DF5), Color(0xFFF53D9E)],
    primaryButtonText: Color(0xFF6A2DBF),
    dialogCard: Color(0xFF4A2FB0),
    tiles: {
      2: TileColors(Color(0xFFD9DBF7), Color(0xFF1E2A4A)),
      4: TileColors(Color(0xFF7FE0D2), Color(0xFF1E2A4A)),
      8: TileColors(Color(0xFFFFB23F), _w),
      16: TileColors(Color(0xFFFF5B5B), _w),
      32: TileColors(Color(0xFFFF4D9D), _w),
      64: TileColors(Color(0xFFFF6A3D), _w),
      128: TileColors(Color(0xFFFFC93C), _w),
      256: TileColors(Color(0xFF54CC57), _w),
      512: TileColors(Color(0xFF3FA3F0), _w),
      1024: TileColors(Color(0xFFB14CFF), _w),
      2048: TileColors(Color(0xFFFFC12E), _w),
    },
  ),
  GameTheme(
    id: 'neon',
    name: 'Midnight Neon',
    isPremium: true,
    backgroundGradient: [Color(0xFF1C1140), Color(0xFF0C0D18)],
    primaryButtonText: Color(0xFF3A2A8C),
    dialogCard: Color(0xFF1C1140),
    boardBackground: Color(0x12FFFFFF),
    emptyCell: Color(0x0AFFFFFF),
    glassStroke: Color(0x33FFFFFF),
    overlayScrim: Color(0xE60C0D18),
    tiles: {
      2: TileColors(Color(0xFF222A4D), Color(0xFF8FA3FF)),
      4: TileColors(Color(0xFF2B2360), Color(0xFFC0A3FF)),
      8: TileColors(Color(0xFF00D4FF), Color(0xFF04222B)),
      16: TileColors(Color(0xFF7B5CFF), _w),
      32: TileColors(Color(0xFFFF4DD2), _w),
      64: TileColors(Color(0xFF00E5A0), Color(0xFF04241A)),
      128: TileColors(Color(0xFFFFD166), Color(0xFF3A2A00)),
      256: TileColors(Color(0xFFFF6A3D), _w),
      512: TileColors(Color(0xFF26C6FF), Color(0xFF04222B)),
      1024: TileColors(Color(0xFFB14CFF), _w),
      2048: TileColors(Color(0xFFFFE14D), Color(0xFF3A2A00)),
    },
  ),
  GameTheme(
    id: 'ocean',
    name: 'Ocean Breeze',
    isPremium: true,
    backgroundGradient: [Color(0xFF0277BD), Color(0xFF26C6DA), Color(0xFF80DEEA)],
    primaryButtonText: Color(0xFF006064),
    dialogCard: Color(0xFF006064),
    overlayScrim: Color(0xCC013440),
    tiles: {
      2: TileColors(Color(0xFFE0F7FA), Color(0xFF006064)),
      4: TileColors(Color(0xFFB2EBF2), Color(0xFF006064)),
      8: TileColors(Color(0xFF4DD0E1), Color(0xFF00363A)),
      16: TileColors(Color(0xFF26C6DA), _w),
      32: TileColors(Color(0xFF00ACC1), _w),
      64: TileColors(Color(0xFF0097A7), _w),
      128: TileColors(Color(0xFF00838F), _w),
      256: TileColors(Color(0xFF006064), _w),
      512: TileColors(Color(0xFF004D6E), _w),
      1024: TileColors(Color(0xFF1DE9B6), Color(0xFF003D33)),
      2048: TileColors(Color(0xFF00E5FF), Color(0xFF00363A)),
    },
  ),
  GameTheme(
    id: 'sunset',
    name: 'Sunset Glow',
    isPremium: true,
    backgroundGradient: [Color(0xFF2B1055), Color(0xFF7D2A6B), Color(0xFFFF8A5C)],
    primaryButtonText: Color(0xFF8E2A6B),
    dialogCard: Color(0xFF5A1E54),
    tiles: {
      2: TileColors(Color(0xFFFFE0B2), Color(0xFF5D4037)),
      4: TileColors(Color(0xFFFFCC80), Color(0xFF5D4037)),
      8: TileColors(Color(0xFFFFB74D), _w),
      16: TileColors(Color(0xFFFF8A65), _w),
      32: TileColors(Color(0xFFFF7043), _w),
      64: TileColors(Color(0xFFF4511E), _w),
      128: TileColors(Color(0xFFE64A19), _w),
      256: TileColors(Color(0xFFD81B60), _w),
      512: TileColors(Color(0xFF8E24AA), _w),
      1024: TileColors(Color(0xFFFFCA28), Color(0xFF5D4037)),
      2048: TileColors(Color(0xFFFF5E62), _w),
    },
  ),
  GameTheme(
    id: 'forest',
    name: 'Emerald Forest',
    isPremium: true,
    backgroundGradient: [Color(0xFF0F3D2E), Color(0xFF1D6B4F), Color(0xFF5FC28C)],
    primaryButtonText: Color(0xFF1B5E20),
    dialogCard: Color(0xFF14503A),
    overlayScrim: Color(0xCC0B2E22),
    tiles: {
      2: TileColors(Color(0xFFE8F5E9), Color(0xFF1B5E20)),
      4: TileColors(Color(0xFFC8E6C9), Color(0xFF1B5E20)),
      8: TileColors(Color(0xFFA5D6A7), Color(0xFF1B5E20)),
      16: TileColors(Color(0xFF66BB6A), _w),
      32: TileColors(Color(0xFF43A047), _w),
      64: TileColors(Color(0xFF2E7D32), _w),
      128: TileColors(Color(0xFF1B5E20), _w),
      256: TileColors(Color(0xFF00C853), Color(0xFF06351B)),
      512: TileColors(Color(0xFF00BFA5), _w),
      1024: TileColors(Color(0xFFAEEA00), Color(0xFF33420A)),
      2048: TileColors(Color(0xFFFFD54F), Color(0xFF3A2A00)),
    },
  ),
  GameTheme(
    id: 'gold',
    name: 'Royal Gold',
    isPremium: true,
    backgroundGradient: [Color(0xFF2A2417), Color(0xFF0D0D0D)],
    primaryButtonText: Color(0xFF5A4500),
    dialogCard: Color(0xFF1A1A1A),
    boardBackground: Color(0x1AD4AF37),
    emptyCell: Color(0x0DD4AF37),
    glassStroke: Color(0x40D4AF37),
    scoreBox: Color(0x1FD4AF37),
    overlayScrim: Color(0xE60D0D0D),
    tiles: {
      2: TileColors(Color(0xFF2C2C2C), Color(0xFFD4AF37)),
      4: TileColors(Color(0xFF3A3A3A), Color(0xFFF0D77B)),
      8: TileColors(Color(0xFFD4AF37), Color(0xFF1A1A1A)),
      16: TileColors(Color(0xFFE6C34D), Color(0xFF1A1A1A)),
      32: TileColors(Color(0xFFCAA92E), Color(0xFF1A1A1A)),
      64: TileColors(Color(0xFFB8860B), _w),
      128: TileColors(Color(0xFFFFD700), Color(0xFF1A1A1A)),
      256: TileColors(Color(0xFFFFF3B0), Color(0xFF5A4500)),
      512: TileColors(Color(0xFF9E7B0A), _w),
      1024: TileColors(Color(0xFFFBE27A), Color(0xFF4A3800)),
      2048: TileColors(Color(0xFFFFDF3D), Color(0xFF3A2A00)),
    },
  ),
  GameTheme(
    id: 'candy',
    name: 'Candy Pop',
    isPremium: true,
    backgroundGradient: [Color(0xFFA18CD1), Color(0xFFC197E8), Color(0xFFFBC2EB)],
    primaryButtonText: Color(0xFF7A2E5D),
    dialogCard: Color(0xFF7A4E9E),
    boardBackground: Color(0x40FFFFFF),
    emptyCell: Color(0x59FFFFFF),
    glassStroke: Color(0x80FFFFFF),
    onBackground: Color(0xFF4A2A5E),
    scoreBox: Color(0x59FFFFFF),
    scoreLabel: Color(0xFF6A4A7E),
    ghostButton: Color(0x66FFFFFF),
    tiles: {
      2: TileColors(Color(0xFFFFF0F6), Color(0xFF7A2E5D)),
      4: TileColors(Color(0xFFFFD6EC), Color(0xFF7A2E5D)),
      8: TileColors(Color(0xFFFF9ECB), _w),
      16: TileColors(Color(0xFFFF6FA5), _w),
      32: TileColors(Color(0xFFC98BFF), _w),
      64: TileColors(Color(0xFF8A6BFF), _w),
      128: TileColors(Color(0xFF5EC8FF), Color(0xFF063047)),
      256: TileColors(Color(0xFF5ED6A8), Color(0xFF06351F)),
      512: TileColors(Color(0xFFFFD166), Color(0xFF6A3B00)),
      1024: TileColors(Color(0xFFFF8FAB), _w),
      2048: TileColors(Color(0xFFFFB3C6), Color(0xFF7A002E)),
    },
  ),
];
