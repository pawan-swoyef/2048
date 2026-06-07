// Picks the interstitial controller per platform: the real google_mobile_ads
// implementation on mobile (dart:io), a no-op on web/desktop.
export 'interstitial_ad_stub.dart'
    if (dart.library.io) 'interstitial_ad_io.dart';
