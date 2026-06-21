import 'dart:math';

import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// The big centered stat shown on a [WinCard] (e.g. "You reached / 512 / in
/// 252 moves").
class WinStat {
  final String label; // small line above the value, e.g. "You reached"
  final String value; // the big highlighted value, e.g. "512"
  final String? sub; // small line below, e.g. "in 252 moves"
  const WinStat({required this.label, required this.value, this.sub});
}

/// A shared celebration card used by every game's win / result screen.
///
/// Layout matches the "SOLVED!" mockup (crown + sunburst, ribbon banner, big
/// stat with laurels, optional streak pill, primary button, optional footer)
/// but takes its colors from the active [GameTheme] so it looks native in all
/// themes. Set [celebrate] to false for a muted variant (fail / game over):
/// no crown, no confetti.
class WinCard extends StatelessWidget {
  final String? banner; // ribbon text, e.g. "SOLVED!" (null hides the ribbon)
  final String headline; // e.g. "Great job! 🎉"
  final WinStat stat;
  final String? badge; // pill, e.g. "🔥 1 day daily streak"
  final String primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? footerLabel; // e.g. "Next puzzle in"
  final String? footerValue; // e.g. "10h 47m"
  final IconData footerIcon;
  final VoidCallback? onClose;
  final VoidCallback? onShare; // optional share icon at the top-left corner
  final bool celebrate;

  // Optional outlined "rewarded" action shown ABOVE the primary button (e.g.
  // "Undo · Watch Ad" on the game-over card). Hidden unless [onAdAction] is set.
  final String? adActionLabel;
  final IconData? adActionIcon;
  final VoidCallback? onAdAction;

  // Emoji shown overhanging the top when [celebrate] is false (game over).
  final String mutedEmoji;

  const WinCard({
    super.key,
    this.banner,
    required this.headline,
    required this.stat,
    this.badge,
    required this.primaryLabel,
    this.primaryIcon,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.footerLabel,
    this.footerValue,
    this.footerIcon = Icons.event_outlined,
    this.onClose,
    this.onShare,
    this.celebrate = true,
    this.adActionLabel,
    this.adActionIcon,
    this.onAdAction,
    this.mutedEmoji = '🏁',
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final card = theme.dialogCard;
    final cardTop = Color.lerp(card, Colors.white, 0.14)!;
    final accent = theme.win;
    final stroke = Color.lerp(card, Colors.white, 0.30)!;
    final panel = const Color(0x14FFFFFF);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // The card itself, padded down so the crown can overhang the top.
        Padding(
          padding: const EdgeInsets.only(top: 46),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [cardTop, card],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: stroke, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: celebrate ? 0.22 : 0.0),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
                const BoxShadow(
                    color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 12)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(22, 44, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (banner != null) ...[
                  _Ribbon(text: banner!, fill: cardTop, accent: accent, stroke: stroke),
                  const SizedBox(height: 16),
                ],
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                _StatPanel(stat: stat, accent: accent, panel: panel, stroke: stroke),
                if (badge != null) ...[
                  const SizedBox(height: 14),
                  _BadgePill(text: badge!, accent: accent),
                ],
                const SizedBox(height: 16),
                if (onAdAction != null && adActionLabel != null) ...[
                  _AdButton(
                    label: adActionLabel!,
                    icon: adActionIcon,
                    accent: accent,
                    onPressed: onAdAction!,
                  ),
                  const SizedBox(height: 10),
                ],
                _PrimaryButton(
                  label: primaryLabel,
                  icon: primaryIcon,
                  accent: accent,
                  textColor: theme.primaryButtonText,
                  onPressed: onPrimary,
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 10),
                  _SecondaryButton(
                      label: secondaryLabel!, stroke: stroke, onPressed: onSecondary!),
                ],
                if (footerValue != null) ...[
                  const SizedBox(height: 16),
                  _Footer(
                    icon: footerIcon,
                    label: footerLabel ?? '',
                    value: footerValue!,
                    accent: accent,
                    panel: panel,
                    stroke: stroke,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Crown + sunburst, overhanging the top edge of the card.
        if (celebrate)
          const Positioned(top: 0, child: _Crown())
        else
          Positioned(top: 8, child: Text(mutedEmoji, style: const TextStyle(fontSize: 44))),

        // Close (X) button at the top-right corner.
        if (onClose != null)
          Positioned(
            top: 50,
            right: 0,
            child: _CornerButton(
                icon: Icons.close, stroke: stroke, onPressed: onClose!),
          ),

        // Share button at the top-left corner (mirrors the close button).
        if (onShare != null)
          Positioned(
            top: 50,
            left: 0,
            child: _CornerButton(
                icon: Icons.share, stroke: stroke, onPressed: onShare!),
          ),
      ],
    );
  }
}

/// A full-screen scrim + animated entrance wrapping a [WinCard]. Drop this into
/// a [Stack] with `Positioned.fill` (or use it directly as an overlay child).
class WinCardOverlay extends StatelessWidget {
  final WinCard child;
  const WinCardOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scrim = ThemeScope.of(context).overlayScrim;
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, t, _) {
          final tc = t.clamp(0.0, 1.0);
          return Container(
            color: scrim.withValues(alpha: scrim.a * tc),
            child: Stack(
              children: [
                if (child.celebrate) const Positioned.fill(child: _Confetti()),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Opacity(
                      opacity: tc,
                      child: Transform.scale(
                        scale: 0.85 + 0.15 * t,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Crown extends StatelessWidget {
  const _Crown();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 92,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(150, 150), painter: _SunburstPainter()),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('👑', style: TextStyle(fontSize: 60)),
          ),
        ],
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  static const _gold = Color(0xFFFFD23F);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    canvas.drawCircle(
      center,
      maxR,
      Paint()
        ..shader = RadialGradient(colors: [
          _gold.withValues(alpha: 0.55),
          _gold.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: center, radius: maxR)),
    );

    final ray = Paint()..color = _gold.withValues(alpha: 0.45);
    const count = 16;
    for (var i = 0; i < count; i++) {
      final a = (i / count) * 2 * pi;
      final inner = center + Offset(cos(a), sin(a)) * (maxR * 0.28);
      final outer = center + Offset(cos(a), sin(a)) * maxR;
      final perp = Offset(-sin(a), cos(a)) * 3.0;
      final path = Path()
        ..moveTo(inner.dx + perp.dx, inner.dy + perp.dy)
        ..lineTo(inner.dx - perp.dx, inner.dy - perp.dy)
        ..lineTo(outer.dx, outer.dy)
        ..close();
      canvas.drawPath(path, ray);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// An outlined, accent-colored "rewarded" button (e.g. "Undo · Watch Ad"),
/// visually distinct from the solid primary button it sits above.
class _AdButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color accent;
  final VoidCallback onPressed;
  const _AdButton(
      {required this.label, this.icon, required this.accent, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withValues(alpha: 0.8), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: accent, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(label,
                    style: TextStyle(
                        color: accent, fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ribbon extends StatelessWidget {
  final String text;
  final Color fill;
  final Color accent;
  final Color stroke;
  const _Ribbon(
      {required this.text, required this.fill, required this.accent, required this.stroke});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stroke, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: accent, size: 22),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                shadows: [Shadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.star_rounded, color: accent, size: 22),
        ],
      ),
    );
  }
}

class _StatPanel extends StatelessWidget {
  final WinStat stat;
  final Color accent;
  final Color panel;
  final Color stroke;
  const _StatPanel(
      {required this.stat, required this.accent, required this.panel, required this.stroke});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stroke.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Laurel(color: accent.withValues(alpha: 0.55)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(stat.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  stat.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: accent,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    shadows: const [
                      Shadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))
                    ],
                  ),
                ),
                if (stat.sub != null) ...[
                  const SizedBox(height: 4),
                  Text(stat.sub!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 15)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Laurel(color: accent.withValues(alpha: 0.55), mirror: true),
        ],
      ),
    );
  }
}

/// A small laurel branch drawn from leaves, flanking the stat value.
class _Laurel extends StatelessWidget {
  final Color color;
  final bool mirror;
  const _Laurel({required this.color, this.mirror = false});

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: mirror,
      child: CustomPaint(size: const Size(34, 78), painter: _LaurelPainter(color)),
    );
  }
}

class _LaurelPainter extends CustomPainter {
  final Color color;
  _LaurelPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final stem = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Curved stem from bottom to top.
    final path = Path()
      ..moveTo(size.width * 0.85, size.height)
      ..quadraticBezierTo(
          size.width * 0.1, size.height * 0.5, size.width * 0.55, 0);
    canvas.drawPath(path, stem);

    // Leaves along the stem.
    const n = 5;
    for (var i = 0; i < n; i++) {
      final f = i / (n - 1);
      final p = _along(path, f);
      final leaf = Offset(p.dx - 9, p.dy + 2);
      canvas.save();
      canvas.translate(leaf.dx, leaf.dy);
      canvas.rotate(-0.6 - f * 0.5);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 16, height: 7), paint);
      canvas.restore();
    }
  }

  Offset _along(Path path, double t) {
    final metric = path.computeMetrics().first;
    return metric.getTangentForOffset(metric.length * t)!.position;
  }

  @override
  bool shouldRepaint(covariant _LaurelPainter old) => old.color != color;
}

class _BadgePill extends StatelessWidget {
  final String text;
  final Color accent;
  const _BadgePill({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7A3D);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: orange.withValues(alpha: 0.6), width: 1.4),
        boxShadow: [BoxShadow(color: orange.withValues(alpha: 0.25), blurRadius: 14)],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color accent;
  final Color textColor;
  final VoidCallback onPressed;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label.toUpperCase(),
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5),
    );
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 18)],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: textColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 22),
          label: child,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final Color stroke;
  final VoidCallback onPressed;
  const _SecondaryButton(
      {required this.label, required this.stroke, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: stroke, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color panel;
  final Color stroke;
  const _Footer({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.panel,
    required this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stroke.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: accent, size: 26),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label.isNotEmpty)
                Text(label,
                    style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
              Text(value,
                  style: TextStyle(
                      color: accent, fontSize: 22, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CornerButton extends StatelessWidget {
  final IconData icon;
  final Color stroke;
  final VoidCallback onPressed;
  const _CornerButton(
      {required this.icon, required this.stroke, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x33000000),
      shape: CircleBorder(side: BorderSide(color: stroke, width: 1.5)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Confetti
// ---------------------------------------------------------------------------

class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFFFF5BA3),
    Color(0xFF3FA3F0),
    Color(0xFFFFC93C),
    Color(0xFF54CC57),
    Color(0xFFB14CFF),
    Color(0xFFFF6A3D),
  ];

  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = Random(7);
    _particles = List.generate(34, (i) {
      return _Particle(
        startX: rnd.nextDouble(),
        startY: -0.05 - rnd.nextDouble() * 0.15,
        fall: 0.55 + rnd.nextDouble() * 0.5,
        drift: (rnd.nextDouble() - 0.5) * 0.25,
        size: 7 + rnd.nextDouble() * 7,
        spins: 1 + rnd.nextDouble() * 3,
        delay: rnd.nextDouble() * 0.25,
        color: _colors[i % _colors.length],
        ratio: 0.4 + rnd.nextDouble() * 0.6,
      );
    });
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..forward();
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
        builder: (context, _) =>
            CustomPaint(painter: _ConfettiPainter(_particles, _c.value), size: Size.infinite),
      ),
    );
  }
}

class _Particle {
  final double startX, startY, fall, drift, size, spins, delay, ratio;
  final Color color;
  const _Particle({
    required this.startX,
    required this.startY,
    required this.fall,
    required this.drift,
    required this.size,
    required this.spins,
    required this.delay,
    required this.ratio,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final eased = local;
      final y = (p.startY + eased * p.fall) * size.height;
      final x = (p.startX + sin(eased * pi * 2) * p.drift) * size.width;
      final opacity = (1.0 - (local - 0.7) / 0.3).clamp(0.0, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(eased * p.spins * 2 * pi);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * p.ratio),
        Paint()..color = p.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
