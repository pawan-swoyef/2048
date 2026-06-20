import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/daily/daily_rotation.dart';

void main() {
  test('rotation cycles through the games in order and loops', () {
    expect(dailyGameId(1), '2048');
    expect(dailyGameId(2), 'numbertap');
    expect(dailyGameId(3), 'numbersort');
    expect(dailyGameId(4), 'magicsquare');
    expect(dailyGameId(5), '2048'); // loops
    expect(dailyGameId(8), 'magicsquare');
  });

  test('dailyGameIndex is zero-based and wraps', () {
    expect(dailyGameIndex(1), 0);
    expect(dailyGameIndex(4), 3);
    expect(dailyGameIndex(5), 0);
  });

  test('rotation lists exactly the four games', () {
    expect(kDailyRotation, ['2048', 'numbertap', 'numbersort', 'magicsquare']);
  });
}
