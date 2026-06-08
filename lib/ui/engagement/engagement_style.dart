import 'package:flutter/material.dart';

import '../theme_controller.dart';

// Brand/currency colors — intentionally constant across all themes.
const Color kCoinGold = Color(0xFFF5C542);
const Color kFlame = Color(0xFFFF8A3D);

/// A small glossy gold coin, used wherever a coin amount is shown.
class CoinIcon extends StatelessWidget {
  final double size;
  const CoinIcon({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFFFFE9A8), kCoinGold, Color(0xFFD99E1E)],
          stops: [0, 0.6, 1],
        ),
        border: Border.all(color: const Color(0xFFC98A14), width: 1.2),
      ),
      child: Icon(Icons.star_rounded, size: size * 0.62, color: const Color(0xFF8A5A06)),
    );
  }
}

/// Pill chrome matching the score boxes, styled by the active theme.
BoxDecoration pillDecoration(GameTheme theme) => BoxDecoration(
      color: theme.scoreBox,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: theme.glassStroke, width: 1.1),
    );
