import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/magicsquare/hint_allowance.dart';

void main() {
  test('a fresh day grants one free ad-hint', () {
    final a = HintAllowance.forToday(
      premium: false,
      storedDate: '2026-06-18',
      storedUsed: 1,
      today: '2026-06-19',
    );
    expect(a.remaining, 1);
    expect(a.canHint, true);
  });

  test('using the daily ad-hint blocks the next one', () {
    final a = HintAllowance.forToday(
      premium: false,
      storedDate: '2026-06-19',
      storedUsed: 1,
      today: '2026-06-19',
    );
    expect(a.remaining, 0);
    expect(a.canHint, false);
  });

  test('premium is unlimited regardless of used count', () {
    final a = HintAllowance.forToday(
      premium: true,
      storedDate: '2026-06-19',
      storedUsed: 5,
      today: '2026-06-19',
    );
    expect(a.unlimited, true);
    expect(a.canHint, true);
  });

  test('a non-premium user is not unlimited', () {
    final a = HintAllowance.forToday(
      premium: false,
      storedDate: '2026-06-19',
      storedUsed: 0,
      today: '2026-06-19',
    );
    expect(a.unlimited, false);
  });
}
