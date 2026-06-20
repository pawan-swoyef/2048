import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/daily/daily_share.dart';

void main() {
  test('includes game title, puzzle number, result and streak', () {
    final text = dailyShareText(
      gameTitle: '2048',
      puzzleNumber: 128,
      result: '🎯512 in 47 moves',
      dailyStreak: 5,
    );
    expect(text, contains('2048 Daily #128'));
    expect(text, contains('512'));
    expect(text, contains('47'));
    expect(text, contains('🔥5'));
  });

  test('works for a time-based game', () {
    final text = dailyShareText(
      gameTitle: 'Magic Square',
      puzzleNumber: 4,
      result: '⏱️ 20.1s',
      dailyStreak: 8,
    );
    expect(text, contains('Magic Square Daily #4'));
    expect(text, contains('20.1s'));
  });

  test('appends the link on its own line when provided', () {
    final text = dailyShareText(
      gameTitle: '2048',
      puzzleNumber: 1,
      result: '🎯512 in 30 moves',
      dailyStreak: 1,
      link: 'https://example.com',
    );
    expect(text, contains('\nhttps://example.com'));
  });
}
