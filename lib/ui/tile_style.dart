import 'package:flutter/material.dart';

/// The "Aurora Glass" theme: a vibrant purple→pink gradient background with
/// translucent, frosted-glass surfaces.
class GameColors {
  // Background gradient stops.
  static const gradientTop = Color(0xFF5B3DF5);
  static const gradientMid = Color(0xFFA23DF5);
  static const gradientBottom = Color(0xFFF53D9E);

  // Glass surfaces (translucent white over the gradient).
  static const boardBackground = Color(0x24FFFFFF); // ~14% white panel
  static const emptyCell = Color(0x1AFFFFFF); // ~10% white
  static const glassStroke = Color(0x59FFFFFF); // ~35% white rim
  static const scoreBox = Color(0x2EFFFFFF); // ~18% white

  // Text.
  static const lightText = Colors.white;
  static const darkText = Colors.white; // body text sits on the gradient
  static const scoreLabel = Color(0xCCFFFFFF); // white70

  // Buttons.
  static const primaryButton = Colors.white;
  static const buttonText = Color(0xFF6A2DBF); // purple text on white button
  static const ghostButton = Color(0x38FFFFFF); // ~22% white

  // Dialogs & overlays.
  static const dialogCard = Color(0xFF4A2FB0);
  static const overlayScrim = Color(0xCC2E1A66); // dark purple, ~80%
  static const win = Color(0xFFFFD23F);
}

/// Background and text color for a tile of a given [value].
class TileStyle {
  final Color background;
  final Color textColor;

  const TileStyle(this.background, this.textColor);

  static const _navy = Color(0xFF1E2A4A);

  // Glossy candy tiles: solid vibrant colors, dark numbers on the light 2/4
  // tiles and white numbers on the rest.
  static const _styles = <int, TileStyle>{
    2: TileStyle(Color(0xFFD9DBF7), _navy), // light lavender
    4: TileStyle(Color(0xFF7FE0D2), _navy), // aqua
    8: TileStyle(Color(0xFFFFB23F), Colors.white), // amber
    16: TileStyle(Color(0xFFFF5B5B), Colors.white), // red
    32: TileStyle(Color(0xFFFF4D9D), Colors.white), // pink
    64: TileStyle(Color(0xFFFF6A3D), Colors.white), // orange-red
    128: TileStyle(Color(0xFFFFC93C), Colors.white), // gold
    256: TileStyle(Color(0xFF54CC57), Colors.white), // green
    512: TileStyle(Color(0xFF3FA3F0), Colors.white), // blue
    1024: TileStyle(Color(0xFFB14CFF), Colors.white), // violet
    2048: TileStyle(Color(0xFFFFC12E), Colors.white), // glowing gold
  };

  /// Style for [value]; values above 2048 reuse the 2048 styling.
  static TileStyle of(int value) => _styles[value] ?? _styles[2048]!;

  /// Font size scaled down for longer numbers, relative to tile [size].
  static double fontSizeFor(int value, double size) {
    if (value < 100) return size * 0.45;
    if (value < 1000) return size * 0.38;
    return size * 0.30;
  }
}
