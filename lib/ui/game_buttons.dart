import 'package:flutter/material.dart';

import 'tile_style.dart';

/// Filled primary action button (e.g. "New Game", "Keep Going").
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _BaseButton(
      label: label,
      onPressed: onPressed,
      background: GameColors.primaryButton,
      textColor: GameColors.buttonText,
    );
  }
}

/// Secondary "ghost" button (e.g. "Cancel").
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const GhostButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _BaseButton(
      label: label,
      onPressed: onPressed,
      background: GameColors.ghostButton,
      textColor: GameColors.darkText,
    );
  }
}

class _BaseButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color textColor;

  const _BaseButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small round icon button used for "How to play" (the "?").
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const IconActionButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GameColors.ghostButton,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 18, color: GameColors.darkText),
        ),
      ),
    );
  }
}
