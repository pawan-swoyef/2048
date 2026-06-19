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

  testWidgets('lists every game in the collection', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('2048'), findsOneWidget);
    expect(find.text('Number Tap'), findsOneWidget);
    expect(find.text('Daily Challenge'), findsOneWidget);
  });
}
