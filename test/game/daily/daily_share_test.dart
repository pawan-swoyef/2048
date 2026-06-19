import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/daily/daily_share.dart';

void main() {
  test('a win includes puzzle number, target, moves and streak', () {
    final text = dailyShareText(
        puzzleNumber: 128, target: 512, success: true, moves: 47, dailyStreak: 5);
    expect(text, contains('#128'));
    expect(text, contains('512'));
    expect(text, contains('47'));
    expect(text, contains('🔥5'));
  });

  test('a DNF reads as "didn\'t make it"', () {
    final text = dailyShareText(
        puzzleNumber: 128, target: 512, success: false, moves: 0, dailyStreak: 0);
    expect(text.toLowerCase(), contains("didn't make it"));
  });

  test('appends the link on its own line when provided', () {
    final text = dailyShareText(
        puzzleNumber: 1,
        target: 512,
        success: true,
        moves: 30,
        dailyStreak: 1,
        link: 'https://example.com');
    expect(text, contains('\nhttps://example.com'));
  });
}
