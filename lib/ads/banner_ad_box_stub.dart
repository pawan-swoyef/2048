import 'package:flutter/material.dart';

import 'ad_placeholder.dart';

/// Web (and any non-dart:io platform): ads aren't supported, so show a
/// placeholder that reserves the same space.
class BannerAdBox extends StatelessWidget {
  const BannerAdBox({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdPlaceholder(label: 'Ad (shows on mobile)');
}
