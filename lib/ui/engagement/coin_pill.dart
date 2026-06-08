import 'package:flutter/material.dart';

import '../theme_controller.dart';
import 'engagement_style.dart';

/// A pill showing the player's coin balance.
class CoinPill extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;

  const CoinPill({super.key, required this.coins, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: pillDecoration(theme),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 18),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: TextStyle(
              color: theme.onBackground,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: pill,
    );
  }
}
