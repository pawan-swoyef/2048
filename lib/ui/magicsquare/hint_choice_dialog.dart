import 'package:flutter/material.dart';

import '../theme_controller.dart';

/// What the player chose in the hint dialog.
enum HintChoice { goPremium, watchAd }

/// Asks a free player how to get a hint: watch a rewarded ad (only when an
/// ad-hint is still available today) or go premium. Returns null if dismissed.
/// Premium players never see this — the screen reveals a hint directly.
Future<HintChoice?> showHintChoiceDialog(
  BuildContext context, {
  required bool showWatchAd,
}) {
  return showDialog<HintChoice>(
    context: context,
    builder: (ctx) => _HintChoiceDialog(showWatchAd: showWatchAd),
  );
}

class _HintChoiceDialog extends StatelessWidget {
  final bool showWatchAd;
  const _HintChoiceDialog({required this.showWatchAd});

  @override
  Widget build(BuildContext context) {
    final card = ThemeScope.of(context).dialogCard;
    return Dialog(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💡', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            const Text('Need a hint?',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              showWatchAd
                  ? 'Reveal one correct number.'
                  : "You've used today's free hint. Go unlimited with Premium.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (showWatchAd) ...[
              _ChoiceButton(
                icon: Icons.ondemand_video_rounded,
                label: 'Watch Ad',
                sub: 'Get 1 hint',
                fill: Colors.white,
                fg: const Color(0xFF6A2DBF),
                onTap: () => Navigator.pop(context, HintChoice.watchAd),
              ),
              const SizedBox(height: 12),
            ],
            _ChoiceButton(
              icon: Icons.workspace_premium_rounded,
              label: 'Go Premium',
              sub: 'Unlimited hints, no ads',
              fill: const Color(0x33FFFFFF),
              fg: Colors.white,
              outlined: true,
              onTap: () => Navigator.pop(context, HintChoice.goPremium),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe later',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color fill;
  final Color fg;
  final bool outlined;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.sub,
    required this.fill,
    required this.fg,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: outlined
                ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4)
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: fg, fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(sub,
                      style: TextStyle(
                          color: fg.withValues(alpha: 0.8), fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
