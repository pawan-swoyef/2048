import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_placeholder.dart';

/// Mobile banner ad. Uses Google's official TEST ad unit IDs so it's safe to
/// run without an AdMob account. Replace [_androidTestUnit] / [_iosTestUnit]
/// with your real AdMob ad unit IDs before publishing.
class BannerAdBox extends StatefulWidget {
  const BannerAdBox({super.key});

  @override
  State<BannerAdBox> createState() => _BannerAdBoxState();
}

class _BannerAdBoxState extends State<BannerAdBox> {
  // Real AdMob banner ad unit (Android). iOS still uses Google's test unit
  // until a real iOS ad unit is provided.
  static const _androidBannerUnit = 'ca-app-pub-9535862781635221/6393745465';
  static const _iosTestUnit = 'ca-app-pub-3940256099942544/2934735716';

  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!(Platform.isAndroid || Platform.isIOS)) return; // desktop: skip
    final adUnitId = Platform.isAndroid ? _androidBannerUnit : _iosTestUnit;
    final ad = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded && _ad != null) {
      return Container(
        height: _ad!.size.height.toDouble(),
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.10),
        alignment: Alignment.center,
        child: SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      );
    }
    return const AdPlaceholder();
  }
}
