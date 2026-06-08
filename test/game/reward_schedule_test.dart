import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/reward_schedule.dart';

void main() {
  group('giftCoins', () {
    test('pays the 7-day ramp for days 1 through 7', () {
      expect(giftCoins(1), 10);
      expect(giftCoins(2), 20);
      expect(giftCoins(3), 30);
      expect(giftCoins(4), 40);
      expect(giftCoins(5), 60);
      expect(giftCoins(6), 80);
      expect(giftCoins(7), 150);
    });
  });

  group('milestoneBonus', () {
    test('pays a bonus only on milestone streak days', () {
      expect(milestoneBonus(3), 30);
      expect(milestoneBonus(7), 70);
      expect(milestoneBonus(14), 150);
      expect(milestoneBonus(30), 500);
    });

    test('pays nothing on non-milestone days', () {
      expect(milestoneBonus(1), 0);
      expect(milestoneBonus(5), 0);
      expect(milestoneBonus(8), 0);
      expect(milestoneBonus(31), 0);
    });
  });

  group('giftDayFor', () {
    test('maps a streak to its position in the repeating 7-day cycle', () {
      expect(giftDayFor(1), 1);
      expect(giftDayFor(7), 7);
      expect(giftDayFor(8), 1);
      expect(giftDayFor(12), 5);
      expect(giftDayFor(14), 7);
    });
  });
}
