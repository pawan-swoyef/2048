import 'package:flutter/material.dart';

import '../theme_controller.dart';
import 'engagement_style.dart';

/// Shows a brief "+N coins" toast at the bottom of the screen.
void showCoinToast(BuildContext context, int amount) {
  final theme = ThemeScope.of(context);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.dialogCard,
        duration: const Duration(seconds: 2),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoinIcon(size: 22),
            const SizedBox(width: 10),
            Text('+$amount coins earned!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
}
