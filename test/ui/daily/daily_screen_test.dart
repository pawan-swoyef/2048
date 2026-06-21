import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/ui/animated_board.dart';
import 'package:game2048/ui/daily/daily_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

Widget _wrap({int? puzzle}) => MaterialApp(
      home: ThemeScope(
        controller: ThemeController(),
        child: DailyScreen(puzzleOverride: puzzle),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('puzzle 1 shows the 2048 daily hero and board', (tester) async {
    await tester.pumpWidget(_wrap(puzzle: 1)); // puzzle 1 -> 2048
    await tester.pumpAndSettle();
    expect(find.text('DAILY #1'), findsOneWidget);
    expect(find.textContaining('2048'), findsWidgets);
    expect(find.textContaining('512'), findsWidgets); // goal chip / goal text
    expect(find.byType(AnimatedBoard), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a pre-saved result shows the result card on open',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'daily_res_puzzle': 1,
      'daily_res_success': true,
      'daily_res_score': 31,
    });
    await tester.pumpWidget(_wrap(puzzle: 1));
    await tester.pumpAndSettle();
    expect(find.text('Great job! 🎉'), findsOneWidget);
    expect(find.textContaining('31'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
  });
}
