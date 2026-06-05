// Picks the right banner implementation per platform: the real google_mobile_ads
// banner on mobile/desktop (dart:io), and a web-safe placeholder otherwise.
export 'banner_ad_box_stub.dart'
    if (dart.library.io) 'banner_ad_box_io.dart';
