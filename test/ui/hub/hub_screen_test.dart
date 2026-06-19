import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/ui/hub/hub_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

Widget _wrap() => MaterialApp(
      home: ThemeScope(controller: ThemeController(), child: const HubScreen()),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('hub shows the title and featured 2048 game', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Number Games'), findsOneWidget);
    expect(find.text('2048'), findsWidgets);
    expect(find.text('Classic merge puzzle'), findsOneWidget);
    expect(find.text('Play Now'), findsOneWidget);
  });

  testWidgets('hub shows the streak and coins stats after rollover',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
  });

  testWidgets('hub lists additional games as compact cards', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Number Tap'), findsOneWidget);
    expect(find.text('Daily Challenge'), findsOneWidget);
  });
}
