import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// A single number tile, styled by the active theme. Tiles flagged with
/// [animateIn] (spawns and merge results) pop in with a scale animation.
class TileWidget extends StatelessWidget {
  final int value;
  final double size;
  final bool animateIn;

  const TileWidget({
    super.key,
    required this.value,
    required this.size,
    this.animateIn = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final colors = theme.tileColors(value);
    final radius = size * 0.18;
    final highlight = Color.lerp(colors.background, Colors.white, 0.30)!;
    final shade = Color.lerp(colors.background, Colors.black, 0.06)!;
    final whiteNumber = colors.text == Colors.white;

    final tile = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, colors.background, shade],
          stops: const [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 9,
            offset: const Offset(0, 5),
          ),
          if (value >= 2048)
            BoxShadow(
              color: colors.background.withValues(alpha: 0.75),
              blurRadius: 22,
              spreadRadius: -2,
            ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: TextStyle(
          color: colors.text,
          fontWeight: FontWeight.w800,
          fontSize: GameTheme.tileFontSize(value, size),
          shadows: whiteNumber
              ? const [
                  Shadow(
                    color: Color(0x33000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
      ),
    );

    if (!animateIn) return tile;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: tile,
    );
  }
}
