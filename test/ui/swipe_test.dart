import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/board.dart';
import 'package:game2048/ui/swipe.dart';

void main() {
  group('swipeDirection', () {
    test('returns null until the drag passes the threshold', () {
      expect(swipeDirection(const Offset(10, 0), threshold: 24), isNull);
      expect(swipeDirection(const Offset(0, 12), threshold: 24), isNull);
    });

    test('detects horizontal swipes once past the threshold', () {
      expect(swipeDirection(const Offset(30, 2), threshold: 24), Direction.right);
      expect(swipeDirection(const Offset(-30, -2), threshold: 24), Direction.left);
    });

    test('detects vertical swipes once past the threshold', () {
      expect(swipeDirection(const Offset(2, 30), threshold: 24), Direction.down);
      expect(swipeDirection(const Offset(-2, -30), threshold: 24), Direction.up);
    });

    test('a diagonal drag picks the dominant axis', () {
      expect(swipeDirection(const Offset(40, 25), threshold: 24), Direction.right);
      expect(swipeDirection(const Offset(20, 40), threshold: 24), Direction.down);
    });
  });
}
