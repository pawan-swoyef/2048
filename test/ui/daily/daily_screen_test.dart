import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/ui/animated_board.dart';
import 'package:game2048/ui/daily/daily_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

Widget _wrap() => MaterialApp(
      home: ThemeScope(controller: ThemeController(), child: const DailyScreen()),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the daily header, goal and board', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.textContaining('Daily'), findsWidgets);
    expect(find.textContaining('512'), findsWidgets); // the goal/target
    expect(find.byType(AnimatedBoard), findsOneWidget);
  });
}
