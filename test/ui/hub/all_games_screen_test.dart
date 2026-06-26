import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/ui/hub/all_games_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

Widget _wrap() => MaterialApp(
      home:
          ThemeScope(controller: ThemeController(), child: const AllGamesScreen()),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('features the Daily Challenge with a Play button', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(find.text('Play Now'), findsOneWidget);
  });

  testWidgets('lists the other games as cards', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    // "2048" appears on both the game's signature tile and its name label.
    expect(find.text('2048'), findsWidgets);
    expect(find.text('Number Tap'), findsOneWidget);
    expect(find.text('Number Sort'), findsOneWidget);
  });
}
