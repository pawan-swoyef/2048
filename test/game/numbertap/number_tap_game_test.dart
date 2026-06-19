import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/numbertap/number_tap_game.dart';

void main() {
  test('board holds exactly the numbers 1..25', () {
    final g = NumberTapGame(Random(1));
    expect(g.board.length, 25);
    expect(g.board.toSet(), {for (var i = 1; i <= 25; i++) i});
  });

  test('starts expecting 1 with no mistakes', () {
    final g = NumberTapGame(Random(1));
    expect(g.next, 1);
    expect(g.mistakes, 0);
    expect(g.isComplete, false);
  });

  test('a correct tap advances next', () {
    final g = NumberTapGame(Random(1));
    g.tap(1);
    expect(g.next, 2);
    expect(g.mistakes, 0);
  });

  test('a wrong tap counts a mistake and leaves next unchanged', () {
    final g = NumberTapGame(Random(1));
    g.tap(5); // expected 1
    expect(g.next, 1);
    expect(g.mistakes, 1);
  });

  test('isCleared reflects numbers already tapped', () {
    final g = NumberTapGame(Random(1));
    g.tap(1);
    g.tap(2);
    expect(g.isCleared(1), true);
    expect(g.isCleared(2), true);
    expect(g.isCleared(3), false);
  });

  test('tapping 1..25 in order completes the game', () {
    final g = NumberTapGame(Random(1));
    for (var n = 1; n <= 25; n++) {
      g.tap(n);
    }
    expect(g.isComplete, true);
    expect(g.mistakes, 0);
  });

  test('penaltySeconds is 2 per mistake', () {
    final g = NumberTapGame(Random(1));
    g.tap(7); // wrong
    g.tap(9); // wrong
    expect(g.penaltySeconds, 4);
  });

  test('taps after completion are ignored', () {
    final g = NumberTapGame(Random(1));
    for (var n = 1; n <= 25; n++) {
      g.tap(n);
    }
    g.tap(3); // should not count
    expect(g.mistakes, 0);
  });
}
