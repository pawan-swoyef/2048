import 'package:flutter/material.dart';

/// Reserves the banner-ad space and shows a subtle placeholder. Used on web /
/// desktop (where ads don't run) and while a real ad is still loading.
class AdPlaceholder extends StatelessWidget {
  final String label;
  const AdPlaceholder({super.key, this.label = 'Ad'});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      color: Colors.black.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
