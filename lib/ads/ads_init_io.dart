import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Initializes the AdMob SDK on Android/iOS. Guarded so it never crashes the app
/// (e.g. on desktop or if Play services are unavailable).
Future<void> initAds() async {
  if (!(Platform.isAndroid || Platform.isIOS)) return;
  try {
    await MobileAds.instance.initialize();
  } catch (_) {
    // Ignore — the game runs fine without ads.
  }
}
