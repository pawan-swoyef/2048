import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/ui/animated_board.dart';
import 'package:game2048/ui/daily/daily_game.dart';
import 'package:game2048/ui/daily/daily_play_controller.dart';
import 'package:game2048/ui/theme_controller.dart';

void main() {
  test('2048 descriptor exposes its metadata', () {
    final g = kDailyGames['2048']!;
    expect(g.id, '2048');
    expect(g.title, '2048');
    expect(g.metricLabel, 'Moves');
    expect(g.goalChip, contains('512'));
    expect(g.formatMetric(8), '8');
  });

  test('2048 result formatting reflects success and failure', () {
    final g = kDailyGames['2048']!;
    final win = g.resultStat(true, 31);
    expect(win.value, '512');
    expect(win.sub, contains('31'));
    expect(g.resultHeadline(true), contains('🎉'));
    expect(g.resultHeadline(false).toLowerCase(), contains('out of moves'));
    expect(g.shareResult(false, 0).toLowerCase(), contains("didn't make it"));
  });

  testWidgets('2048 play renders an AnimatedBoard from the seed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final c = DailyPlayController();
    await tester.pumpWidget(MaterialApp(
      home: ThemeScope(
        controller: ThemeController(),
        child: Scaffold(body: kDailyGames['2048']!.buildPlay(20260101, 100, c)),
      ),
    ));
    await tester.pump();
    expect(find.byType(AnimatedBoard), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
