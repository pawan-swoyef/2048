import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/numbersort/undo_allowance.dart';

void main() {
  test('a fresh day grants the full daily free undos', () {
    final a = UndoAllowance.forToday(
      premium: false,
      storedDate: '2026-06-18',
      storedUsed: 3,
      today: '2026-06-19',
    );
    expect(a.remaining, UndoAllowance.dailyFree);
    expect(a.canUndo, true);
  });

  test('used undos on the same day reduce the remaining count', () {
    final a = UndoAllowance.forToday(
      premium: false,
      storedDate: '2026-06-19',
      storedUsed: 1,
      today: '2026-06-19',
    );
    expect(a.remaining, 2);
    expect(a.canUndo, true);
  });

  test('the daily cap blocks further undos', () {
    final a = UndoAllowance.forToday(
      premium: false,
      storedDate: '2026-06-19',
      storedUsed: 3,
      today: '2026-06-19',
    );
    expect(a.remaining, 0);
    expect(a.canUndo, false);
  });

  test('premium is unlimited regardless of used count', () {
    final a = UndoAllowance.forToday(
      premium: true,
      storedDate: '2026-06-19',
      storedUsed: 3,
      today: '2026-06-19',
    );
    expect(a.unlimited, true);
    expect(a.canUndo, true);
  });

  test('a non-premium user is not unlimited', () {
    final a = UndoAllowance.forToday(
      premium: false,
      storedDate: '2026-06-19',
      storedUsed: 0,
      today: '2026-06-19',
    );
    expect(a.unlimited, false);
  });
}
