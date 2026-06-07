import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// Filled primary action button (e.g. "New Game", "Keep Going").
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return _BaseButton(
      label: label,
      onPressed: onPressed,
      background: theme.primaryButton,
      textColor: theme.primaryButtonText,
    );
  }
}

/// Secondary "ghost" button (e.g. "Cancel"); used over dark dialog/overlay surfaces.
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const GhostButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return _BaseButton(
      label: label,
      onPressed: onPressed,
      background: theme.ghostButton,
      textColor: Colors.white,
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

/// Small icon button used for the toolbar actions (sound, help, theme).
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const IconActionButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return Material(
      color: theme.ghostButton,
      borderRadius: BorderRadius.circular(8),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 18, color: theme.onBackground),
        ),
      ),
    );
  }
}
