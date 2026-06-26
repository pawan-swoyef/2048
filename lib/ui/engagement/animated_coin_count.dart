import 'dart:math';

import 'package:flutter/material.dart';

/// A coin balance number that counts up (with a little scale "bump") whenever
/// its [value] changes — e.g. when the player collects coins. On first build it
/// shows the value immediately; only later changes animate.
class AnimatedCoinCount extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCoinCount(
    this.value, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 650),
  });

  @override
  State<AnimatedCoinCount> createState() => _AnimatedCoinCountState();
}

class _AnimatedCoinCountState extends State<AnimatedCoinCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late int _from = widget.value;
  late int _to = widget.value;

  @override
  void didUpdateWidget(AnimatedCoinCount old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      _from = _shown(); // resume from whatever is currently on screen
      _to = widget.value;
      _c.forward(from: 0);
    }
  }

  int _shown() =>
      (_from + (_to - _from) * Curves.easeOut.transform(_c.value)).round();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final bump = _to > _from ? 1 + 0.22 * sin(_c.value * pi) : 1.0;
        return Transform.scale(
          scale: bump,
          child: Text('${_shown()}', style: widget.style),
        );
      },
    );
  }
}
