import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/sound_service.dart';
import 'engagement_style.dart';

/// Flies a handful of gold coins from [from] (a global screen point) to the
/// coin-balance pill identified by [toKey], with a rapid "coin shower" sound.
/// Pair it with an [AnimatedCoinCount] on the target so the number counts up as
/// the coins land. Returns when the effect finishes.
Future<void> playCoinBurst({
  required BuildContext context,
  required Offset from,
  required GlobalKey toKey,
  required SoundService sound,
  int coins = 11,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final targetBox = toKey.currentContext?.findRenderObject() as RenderBox?;
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  if (targetBox == null || overlayBox == null) {
    sound.coin();
    return;
  }
  final to = overlayBox
      .globalToLocal(targetBox.localToGlobal(targetBox.size.center(Offset.zero)));
  final start = overlayBox.globalToLocal(from);

  final entry =
      OverlayEntry(builder: (_) => _CoinBurst(from: start, to: to, count: coins));
  overlay.insert(entry);

  // Coin-shower: a few quick chimes timed to the coins landing.
  for (var i = 0; i < 5; i++) {
    Future.delayed(Duration(milliseconds: 130 + i * 100), sound.coin);
  }

  await Future.delayed(const Duration(milliseconds: 1150));
  entry.remove();
}

class _Spec {
  final Offset scatter;
  final double delay, arc, size;
  const _Spec(
      {required this.scatter,
      required this.delay,
      required this.arc,
      required this.size});
}

class _CoinBurst extends StatefulWidget {
  final Offset from, to;
  final int count;
  const _CoinBurst({required this.from, required this.to, required this.count});

  @override
  State<_CoinBurst> createState() => _CoinBurstState();
}

class _CoinBurstState extends State<_CoinBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 950))
    ..forward();
  late final List<_Spec> _specs;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    _specs = List.generate(widget.count, (_) {
      final ang = rnd.nextDouble() * 2 * pi;
      final rad = 20 + rnd.nextDouble() * 55;
      return _Spec(
        scatter: Offset(cos(ang) * rad, sin(ang) * rad - 10),
        delay: rnd.nextDouble() * 0.28,
        arc: 40 + rnd.nextDouble() * 80,
        size: 16 + rnd.nextDouble() * 12,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Stack(
          children: [for (final s in _specs) ..._coin(s)],
        ),
      ),
    );
  }

  List<Widget> _coin(_Spec s) {
    final span = 1 - s.delay;
    final lt = ((_c.value - s.delay) / span).clamp(0.0, 1.0);
    if (lt <= 0) return const [];
    final e = Curves.easeInOut.transform(lt);
    final pos = Offset.lerp(widget.from + s.scatter, widget.to, e)!;
    final arcY = -sin(e * pi) * s.arc; // little hop on the way over
    final popIn = lt < 0.16 ? lt / 0.16 : 1.0;
    final scale = popIn * (1 - 0.45 * e); // shrink as it reaches the pill
    final opacity = lt >= 0.9 ? (1 - lt) / 0.1 : 1.0;
    return [
      Positioned(
        left: pos.dx - s.size / 2,
        top: pos.dy + arcY - s.size / 2,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: CoinIcon(size: s.size)),
        ),
      ),
    ];
  }
}
