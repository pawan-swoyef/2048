import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../theme_controller.dart';
import 'engagement_style.dart';

/// Opens the platform's native review flow (Google Play / App Store in-app
/// review sheet), falling back to the store listing. Never throws — a failed
/// review attempt must not crash the game.
Future<void> requestAppReview() async {
  try {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
  } catch (_) {
    // Ignore: review is best-effort.
  }
}

/// A friendly "rate us" card shown over a dimmed game background after a
/// rewarding moment (a daily-challenge win). Celebrates the win, then asks for
/// a rating. Tapping the stars or the primary button triggers the native flow.
class ReviewPromptOverlay extends StatelessWidget {
  final int coins;
  final int streak;
  final VoidCallback onRate;
  final VoidCallback onLater;

  const ReviewPromptOverlay({
    super.key,
    required this.coins,
    required this.streak,
    required this.onRate,
    required this.onLater,
  });

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
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Opacity(
                opacity: tc,
                child: Transform.scale(
                  scale: 0.85 + 0.15 * t,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: _card(context),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 14)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _achievement(),
          const SizedBox(height: 16),
          const Text('Are you enjoying Numjoy?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFF241139), fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Your feedback helps us create better number puzzles.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8A7CA8), fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 16),
          _stars(),
          const SizedBox(height: 18),
          _primaryButton(),
          const SizedBox(height: 10),
          _ghostButton(),
          const SizedBox(height: 12),
          const Text('Thanks for supporting Numjoy! 💜',
              style: TextStyle(
                  color: Color(0xFFB49FD8), fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _achievement() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A5C), Color(0xFFFF5C8A), Color(0xFFC84BD6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFC84BD6).withValues(alpha: 0.35), blurRadius: 18),
        ],
      ),
      child: Column(
        children: [
          const Text('🎉 Daily Challenge Complete!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip(child: const CoinIcon(size: 18), label: '+$coins'),
              const SizedBox(width: 10),
              _chip(
                  child: const Text('🔥', style: TextStyle(fontSize: 15)),
                  label: '$streak Day Streak!'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({required Widget child, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _stars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 5; i++)
          GestureDetector(
            onTap: onRate,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.star_rounded, color: Color(0xFFFFC93C), size: 40),
            ),
          ),
      ],
    );
  }

  Widget _primaryButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onRate,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFF53D9E)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFF53D9E).withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text('Rate Numjoy ⭐',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ghostButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFFF1ECFA),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onLater,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Text('Later',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF6A2DBF), fontSize: 14.5, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }
}
