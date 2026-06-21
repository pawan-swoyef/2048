import 'dart:io';

import 'package:flutter/foundation.dart';
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

  static final InterstitialController _instance = InterstitialController._internal();

  factory InterstitialController() => _instance;

  InterstitialController._internal() {
    _preload();
  }

  InterstitialAd? _ad;
  bool _loading = false;
  bool _premium = false;
  int _gameOverCount = 0;
  DateTime? _lastShown;

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  void setPremium(bool premium) => _premium = premium;

  void _preload() {
    if (!_supported || _premium || _ad != null || _loading) return;
    _loading = true;
    debugPrint('AdMob: Preloading Interstitial Ad...');
    InterstitialAd.load(
      adUnitId: Platform.isAndroid ? _androidUnit : _iosUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdMob: Interstitial Ad loaded successfully.');
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob: Interstitial Ad failed to load: $error');
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
    debugPrint('AdMob: Game Over $_gameOverCount. Interstitial allowed: $allowed');
    if (!allowed) return;

    final ad = _ad;
    if (ad == null) {
      debugPrint('AdMob: Interstitial ad not ready yet.');
      _preload(); // not ready this time; have one ready for next time
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AdMob: Interstitial Ad dismissed.');
        ad.dispose();
        _ad = null;
        _preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob: Interstitial Ad failed to show: $error');
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
    // No-op for singleton to prevent game screens from destroying the cached ad.
  }

  /// Explicitly disposes the cached ad (e.g., when the app is shut down).
  void destroy() {
    _ad?.dispose();
    _ad = null;
  }
}

