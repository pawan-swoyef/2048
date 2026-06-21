import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Loads and shows rewarded ads for the Number Sort undo feature. Uses Google's
/// TEST rewarded units until real ad units are provided. Premium players never
/// see these (the screen calls [show] only for free players).
class RewardedController {
  static const _androidUnit = 'ca-app-pub-9535862781635221/4887405296';
  static const _iosUnit = 'ca-app-pub-3940256099942544/1712485313'; // TEST

  static final RewardedController _instance = RewardedController._internal();

  factory RewardedController() => _instance;

  RewardedController._internal() {
    _preload();
  }

  RewardedAd? _ad;
  bool _loading = false;
  bool _premium = false;

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  void setPremium(bool premium) {
    _premium = premium;
    if (!premium) _preload();
  }

  void _preload() {
    if (!_supported || _premium || _ad != null || _loading) return;
    _loading = true;
    debugPrint('AdMob: Preloading Rewarded Ad...');
    RewardedAd.load(
      adUnitId: Platform.isAndroid ? _androidUnit : _iosUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdMob: Rewarded Ad loaded successfully.');
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob: Rewarded Ad failed to load: $error');
          _ad = null;
          _loading = false;
        },
      ),
    );
  }

  /// Shows a rewarded ad and calls [onReward] only when the reward is genuinely
  /// earned. On an unsupported platform, when no ad is ready, or when the ad
  /// fails to show, [onReward] fires immediately so a missing ad never blocks
  /// the player. A user who dismisses the ad early earns nothing.
  void show(void Function() onReward) {
    if (!_supported) {
      onReward();
      return;
    }
    final ad = _ad;
    if (ad == null) {
      debugPrint('AdMob: No preloaded Rewarded Ad ready. Granting reward anyway.');
      onReward(); // none ready: grant anyway, then load one for next time
      _preload();
      return;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AdMob: Rewarded Ad dismissed by user.');
        ad.dispose();
        _ad = null;
        _preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdMob: Rewarded Ad failed to show: $error');
        ad.dispose();
        _ad = null;
        onReward();
        _preload();
      },
    );
    _ad = null;
    ad.show(onUserEarnedReward: (_, _) {
      debugPrint('AdMob: Rewarded Ad reward earned.');
      onReward();
    });
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

