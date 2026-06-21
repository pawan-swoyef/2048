// Picks the rewarded-ad controller per platform: the real google_mobile_ads
// implementation on mobile (dart:io), a no-op (reward fires immediately) on
// web/desktop and in tests.
export 'rewarded_ad_stub.dart'
    if (dart.library.io) 'rewarded_ad_io.dart';
