import 'dart:math';

import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// The big centered stat shown on a result screen (e.g. "You reached / 512 / in
/// 252 moves").
class WinStat {
  final String label; // small line above the value, e.g. "You reached"
  final String value; // the big highlighted value, e.g. "512"
  final String? sub; // small line below, e.g. "in 252 moves"
  const WinStat({required this.label, required this.value, this.sub});
}

/// A shared full-screen result for every game's win / game-over, styled like a
/// modern mobile game: a sunburst + crown celebration (or a muted emoji on a
/// loss), a bold title, a score panel, an optional reward pill, and chunky
/// "pressable" buttons. Colors come from the active [GameTheme].
///
/// Set [celebrate] to false for the muted game-over variant (no crown / sunburst
/// / confetti). Wrap it in a [WinCardOverlay] to get the full-bleed background
/// and entrance animation.
class WinCard extends StatefulWidget {
  final String? banner; // bold title, e.g. "SOLVED!" (falls back to headline)
  final String headline; // e.g. "Great job! 🎉"
  final WinStat stat;
  final String? badge; // reward pill, e.g. "🪙 +100 · 🔥 5 day streak"
  final String primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? footerLabel; // e.g. "Next puzzle in"
  final String? footerValue; // e.g. "10h 47m"
  final IconData footerIcon;
  final VoidCallback? onClose;
  final VoidCallback? onShare;
  final bool celebrate;

  // Optional "rewarded" action (e.g. "Undo · Watch Ad" / "Keep Going · Watch
  // Ad"). When present it becomes the prominent green button and [primaryLabel]
  // drops to a secondary (ghost) button. Hidden unless [onAdAction] is set.
  final String? adActionLabel;
  final IconData? adActionIcon;
  final VoidCallback? onAdAction;

  // Emoji shown when [celebrate] is false (game over).
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
    this.mutedEmoji = '😵',
  });

  @override
  State<WinCard> createState() => _WinCardState();
}

class _WinCardState extends State<WinCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1150))
    ..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Eased progress for the [begin, end] slice of the controller (0..1+).
  double _seg(double begin, double end, Curve curve) =>
      curve.transform(((_ctrl.value - begin) / (end - begin)).clamp(0.0, 1.0));

  /// Fade + rise (+ optional bouncy scale) reveal over a slice.
  Widget _reveal(double begin, double end,
      {double dy = 18,
      double scaleFrom = 1.0,
      Curve curve = Curves.easeOutCubic,
      required Widget child}) {
    final t = _seg(begin, end, curve);
    final clamped = t.clamp(0.0, 1.0);
    Widget w = Opacity(
      opacity: clamped,
      child: Transform.translate(
          offset: Offset(0, (1 - clamped) * dy), child: child),
    );
    if (scaleFrom != 1.0) {
      w = Transform.scale(scale: scaleFrom + (1 - scaleFrom) * t, child: w);
    }
    return w;
  }

  /// Counts a numeric value string up from 0 as [t] goes 0→1.
  String _countUp(String value, double t) {
    if (t >= 1) return value;
    final m = RegExp(r'^(\d[\d,]*\.?\d*)(.*)$').firstMatch(value);
    if (m == null) return value;
    final numStr = m.group(1)!.replaceAll(',', '');
    final target = double.tryParse(numStr);
    if (target == null) return value;
    final decimals = numStr.contains('.') ? numStr.split('.')[1].length : 0;
    final cur = target * t;
    final shown =
        decimals > 0 ? cur.toStringAsFixed(decimals) : cur.round().toString();
    return '$shown${m.group(2)!}';
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final theme = ThemeScope.of(context);
    final accent = theme.win;
    final hasAd = w.onAdAction != null && w.adActionLabel != null;
    final title = (w.banner ?? w.headline).toUpperCase();
    final subtitle = w.banner != null ? w.headline : null;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final value = w.celebrate
            ? _countUp(w.stat.value, _seg(0.42, 0.92, Curves.easeOut))
            : w.stat.value;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
          child: Column(
            children: [
              _reveal(0.0, 0.3, dy: 0,
                  child: SizedBox(
                    height: 40,
                    child: Row(children: [
                      if (w.onShare != null)
                        _CornerButton(icon: Icons.share, onPressed: w.onShare!)
                      else
                        const SizedBox(width: 40),
                      const Spacer(),
                      if (w.onClose != null)
                        _CornerButton(icon: Icons.close, onPressed: w.onClose!),
                    ]),
                  )),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _reveal(0.0, 0.5,
                            dy: 0,
                            scaleFrom: 0.3,
                            curve: Curves.elasticOut,
                            child: SizedBox(
                              height: 150,
                              child: w.celebrate
                                  ? Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CustomPaint(
                                            size: const Size(240, 240),
                                            painter: _SunburstPainter(accent)),
                                        const Text('👑',
                                            style: TextStyle(fontSize: 78)),
                                      ],
                                    )
                                  : Center(
                                      child: Text(w.mutedEmoji,
                                          style: const TextStyle(fontSize: 76)),
                                    ),
                            )),
                        _reveal(0.18, 0.55,
                            scaleFrom: 0.7,
                            curve: Curves.easeOutBack,
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(
                                      color: Color(0x55000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 3))
                                ],
                              ),
                            )),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          _reveal(0.3, 0.6,
                              dy: 8,
                              child: Text(subtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xCCFFFFFF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600))),
                        ],
                        const SizedBox(height: 18),
                        _reveal(0.4, 0.78,
                            dy: 24,
                            child: _StatPanel(
                                label: w.stat.label,
                                value: value,
                                sub: w.stat.sub,
                                accent: accent)),
                        if (w.badge != null) ...[
                          const SizedBox(height: 12),
                          _reveal(0.55, 0.85,
                              dy: 14,
                              child: _RewardPill(text: w.badge!, accent: accent)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (hasAd) ...[
                _reveal(0.6, 0.92,
                    child: _ChunkyButton(
                        label: w.adActionLabel!,
                        icon: w.adActionIcon,
                        kind: _BtnKind.green,
                        onPressed: w.onAdAction!)),
                const SizedBox(height: 12),
                _reveal(0.68, 1.0,
                    child: _ChunkyButton(
                        label: w.primaryLabel,
                        icon: w.primaryIcon,
                        kind: _BtnKind.ghost,
                        onPressed: w.onPrimary)),
              ] else ...[
                _reveal(0.6, 0.95,
                    child: _ChunkyButton(
                        label: w.primaryLabel,
                        icon: w.primaryIcon,
                        kind: _BtnKind.green,
                        onPressed: w.onPrimary)),
                if (w.secondaryLabel != null && w.onSecondary != null) ...[
                  const SizedBox(height: 12),
                  _reveal(0.68, 1.0,
                      child: _ChunkyButton(
                          label: w.secondaryLabel!,
                          kind: _BtnKind.ghost,
                          onPressed: w.onSecondary!)),
                ],
              ],
              if (w.footerValue != null) ...[
                const SizedBox(height: 14),
                _reveal(0.7, 1.0,
                    dy: 8,
                    child: Text(
                      w.footerLabel != null
                          ? '${w.footerLabel!} ${w.footerValue!}'
                          : w.footerValue!,
                      style: const TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Full-bleed background (the active theme gradient) + confetti + entrance
/// animation, wrapping a [WinCard] so the result reads as a dedicated screen.
class WinCardOverlay extends StatelessWidget {
  final WinCard child;
  const WinCardOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        // Quick background fade-in; the card itself plays the staggered entrance.
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        builder: (context, t, _) {
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.backgroundGradient,
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    if (child.celebrate)
                      const Positioned.fill(child: _Confetti()),
                    child,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _StatPanel extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color accent;
  const _StatPanel(
      {required this.label,
      required this.value,
      this.sub,
      required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x2BFFFFFF), Color(0x10FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x40FFFFFF), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 22,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accent,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              height: 1.0,
              shadows: const [
                Shadow(
                    color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))
              ],
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  final String text;
  final Color accent;
  const _RewardPill({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: accent, size: 18),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BtnKind { green, ghost }

/// A chunky "pressable" button with a hard drop shadow — the casual-game look.
class _ChunkyButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final _BtnKind kind;
  final VoidCallback onPressed;
  const _ChunkyButton({
    required this.label,
    this.icon,
    required this.kind,
    required this.onPressed,
  });

  @override
  State<_ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<_ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final green = widget.kind == _BtnKind.green;
    final fill = green ? const Color(0xFF36CF4A) : const Color(0x1FFFFFFF);
    final shadow = green ? const Color(0xFF239A32) : const Color(0x40000000);
    final textColor = Colors.white;
    final lift = _down ? 0.0 : 5.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: double.infinity,
        margin: EdgeInsets.only(top: 5 - lift, bottom: lift),
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(18),
          border: green
              ? null
              : Border.all(color: const Color(0x66FFFFFF), width: 1.5),
          boxShadow: [
            BoxShadow(color: shadow, blurRadius: 0, offset: Offset(0, lift)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: textColor, size: 21),
              const SizedBox(width: 9),
            ],
            Flexible(
              child: Text(
                widget.label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CornerButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x33000000),
      shape: const CircleBorder(
          side: BorderSide(color: Color(0x59FFFFFF), width: 1.5)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _SunburstPainter extends CustomPainter {
  final Color color;
  _SunburstPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Soft outer glow.
    canvas.drawCircle(
      center,
      maxR,
      Paint()
        ..shader = RadialGradient(colors: [
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0.0),
        ], stops: const [0.15, 1.0])
            .createShader(Rect.fromCircle(center: center, radius: maxR)),
    );

    // Brighter core halo behind the crown.
    canvas.drawCircle(
      center,
      maxR * 0.5,
      Paint()
        ..shader = RadialGradient(colors: [
          color.withValues(alpha: 0.45),
          color.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: center, radius: maxR * 0.5)),
    );

    // A clean ring of tapered rays.
    final ray = Paint()..color = color.withValues(alpha: 0.5);
    const count = 20;
    for (var i = 0; i < count; i++) {
      final a = (i / count) * 2 * pi;
      final inner = center + Offset(cos(a), sin(a)) * (maxR * 0.46);
      final outer = center + Offset(cos(a), sin(a)) * (maxR * 0.98);
      final perp = Offset(-sin(a), cos(a)) * 4.5;
      final path = Path()
        ..moveTo(inner.dx + perp.dx, inner.dy + perp.dy)
        ..lineTo(inner.dx - perp.dx, inner.dy - perp.dy)
        ..lineTo(outer.dx, outer.dy)
        ..close();
      canvas.drawPath(path, ray);
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter old) => old.color != color;
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
    _particles = List.generate(60, (i) {
      return _Particle(
        startX: rnd.nextDouble(),
        startY: -0.05 - rnd.nextDouble() * 0.2,
        fall: 0.7 + rnd.nextDouble() * 0.5,
        drift: (rnd.nextDouble() - 0.5) * 0.28,
        size: 8 + rnd.nextDouble() * 8,
        spins: 1 + rnd.nextDouble() * 3,
        delay: rnd.nextDouble() * 0.25,
        color: _colors[i % _colors.length],
        ratio: 0.4 + rnd.nextDouble() * 0.6,
      );
    });
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
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
        builder: (context, _) => CustomPaint(
            painter: _ConfettiPainter(_particles, _c.value), size: Size.infinite),
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
