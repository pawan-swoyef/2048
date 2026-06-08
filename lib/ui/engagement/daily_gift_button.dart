import 'package:flutter/material.dart';

import '../theme_controller.dart';
import 'engagement_style.dart';

/// A gift-chest button for the header. Glows with a red "ready" dot when a
/// gift can be claimed; dimmed otherwise. Tapping opens the gift dialog.
class DailyGiftButton extends StatelessWidget {
  final bool available;
  final VoidCallback onTap;

  const DailyGiftButton({super.key, required this.available, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Opacity(
        opacity: available ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: pillDecoration(theme).copyWith(
            boxShadow: available
                ? [BoxShadow(color: kCoinGold.withValues(alpha: 0.55), blurRadius: 14)]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 20)),
              if (available)
                Positioned(
                  top: -4,
                  right: -5,
                  child: Container(
                    key: const ValueKey('gift-ready-dot'),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D6D),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.dialogCard, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
