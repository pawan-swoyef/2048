import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/ui/game_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

// The app opens to the hub now; these test the 2048 game screen directly.
// ThemeScope sits above MaterialApp (like main.dart) so dialogs can find it.
Widget _gameScreen() => ThemeScope(
      controller: ThemeController(),
      child: const MaterialApp(home: GameScreen()),
    );

void main() {
  setUp(() {
    // ScoreStore reads from SharedPreferences; provide an in-memory store.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the title, score header, and New Game button', (tester) async {
    await tester.pumpWidget(_gameScreen());
    await tester.pumpAndSettle();

    expect(find.text('2048'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
  });

  testWidgets('opens the How to Play dialog from the help button', (tester) async {
    await tester.pumpWidget(_gameScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('How to Play'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('starts with exactly two tiles on the board', (tester) async {
    await tester.pumpWidget(_gameScreen());
    await tester.pumpAndSettle();

    // Starting tiles are 2s and/or 4s — there should be exactly two of them.
    final twos = find.text('2').evaluate().length;
    final fours = find.text('4').evaluate().length;
    expect(twos + fours, 2);
  });
}
