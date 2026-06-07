import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'interstitial_policy.dart';

/// Loads and shows interstitial ads on game over, throttled by
/// [InterstitialPolicy]. Uses Google's TEST interstitial unit until a real one
/// is provided.
class InterstitialController {
  // Real AdMob interstitial unit (Android). iOS still uses Google's test unit
  // until a real iOS ad unit is provided.
  static const _androidUnit = 'ca-app-pub-9535862781635221/5080663797';
  static const _iosUnit = 'ca-app-pub-3940256099942544/4411468910'; // TEST

  InterstitialAd? _ad;
  bool _loading = false;
  bool _premium = false;
  int _gameOverCount = 0;
  DateTime? _lastShown;

  InterstitialController() {
    _preload();
  }

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  void setPremium(bool premium) => _premium = premium;

  void _preload() {
    if (!_supported || _premium || _ad != null || _loading) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? _androidUnit : _iosUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) {
          _ad = null;
          _loading = false;
        },
      ),
    );
  }

  /// Call when a game ends. Shows an ad if the policy allows and one is ready.
  void onGameOver() {
    if (!_supported || _premium) return;
    _gameOverCount++;

    final allowed = InterstitialPolicy.shouldShow(
      gameOverCount: _gameOverCount,
      lastShown: _lastShown,
      now: DateTime.now(),
      premium: _premium,
    );
    if (!allowed) return;

    final ad = _ad;
    if (ad == null) {
      _preload(); // not ready this time; have one ready for next time
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _preload();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _ad = null;
        _preload();
      },
    );

    _lastShown = DateTime.now();
    _ad = null;
    ad.show();
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
