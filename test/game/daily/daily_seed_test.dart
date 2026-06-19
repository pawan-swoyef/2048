import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/daily/daily_seed.dart';

void main() {
  group('puzzleNumber', () {
    test('counts days from the epoch, starting at 1', () {
      expect(puzzleNumber(DateTime(2026, 1, 1)), 1);
      expect(puzzleNumber(DateTime(2026, 1, 2)), 2);
      expect(puzzleNumber(DateTime(2026, 1, 11)), 11);
    });

    test('ignores the time of day', () {
      expect(puzzleNumber(DateTime(2026, 1, 1, 23, 59)), 1);
    });
  });

  group('dailySeed', () {
    test('is the same for the same date regardless of time', () {
      expect(dailySeed(DateTime(2026, 6, 18, 9)),
          dailySeed(DateTime(2026, 6, 18, 21)));
    });

    test('differs between consecutive days', () {
      expect(dailySeed(DateTime(2026, 6, 18)),
          isNot(dailySeed(DateTime(2026, 6, 19))));
    });
  });
}
