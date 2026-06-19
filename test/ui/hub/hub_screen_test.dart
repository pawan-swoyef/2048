import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/ui/hub/hub_screen.dart';
import 'package:game2048/ui/engagement/streak_pill.dart';
import 'package:game2048/ui/engagement/coin_pill.dart';
import 'package:game2048/ui/theme_controller.dart';

Widget _wrap() => MaterialApp(
      home: ThemeScope(controller: ThemeController(), child: const HubScreen()),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('hub lists the 2048 game card', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('2048'), findsWidgets);
    expect(find.text('Classic merge puzzle'), findsOneWidget);
  });

  testWidgets('hub shows the engagement row after the daily rollover',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byType(StreakPill), findsOneWidget);
    expect(find.byType(CoinPill), findsOneWidget);
  });
}
