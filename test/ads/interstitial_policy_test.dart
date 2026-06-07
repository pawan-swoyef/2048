import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/ads/interstitial_policy.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12, 0, 0);

  group('InterstitialPolicy.shouldShow', () {
    test('never shows for premium users', () {
      expect(
        InterstitialPolicy.shouldShow(
            gameOverCount: 3, lastShown: null, now: now, premium: true),
        isFalse,
      );
    });

    test('does not show before the 3rd game over', () {
      expect(
        InterstitialPolicy.shouldShow(
            gameOverCount: 1, lastShown: null, now: now, premium: false),
        isFalse,
      );
      expect(
        InterstitialPolicy.shouldShow(
            gameOverCount: 2, lastShown: null, now: now, premium: false),
        isFalse,
      );
    });

    test('shows on the 3rd game over when nothing shown yet', () {
      expect(
        InterstitialPolicy.shouldShow(
            gameOverCount: 3, lastShown: null, now: now, premium: false),
        isTrue,
      );
    });

    test('shows again on the 6th game over', () {
      expect(
        InterstitialPolicy.shouldShow(
            gameOverCount: 6,
            lastShown: now.subtract(const Duration(minutes: 5)),
            now: now,
            premium: false),
        isTrue,
      );
    });

    test('respects the minimum interval between ads', () {
      expect(
        InterstitialPolicy.shouldShow(
            gameOverCount: 3,
            lastShown: now.subtract(const Duration(seconds: 30)),
            now: now,
            premium: false),
        isFalse,
      );
      expect(
        InterstitialPolicy.shouldShow(
            gameOverCount: 3,
            lastShown: now.subtract(const Duration(minutes: 3)),
            now: now,
            premium: false),
        isTrue,
      );
    });

    test('does not show on non-multiples of the frequency', () {
      expect(
        InterstitialPolicy.shouldShow(
            gameOverCount: 4, lastShown: null, now: now, premium: false),
        isFalse,
      );
    });
  });
}
