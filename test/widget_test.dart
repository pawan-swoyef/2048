import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/iap/iap_service.dart';
import 'package:game2048/ui/animated_board.dart';
import 'package:game2048/ui/game_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

// The app opens to the hub now; these test the 2048 game screen directly.
// ThemeScope/IAPScope sit above MaterialApp (like main.dart) so dialogs can find them.
Widget _gameScreen({ThemeController? controller}) {
  final tc = controller ?? ThemeController();
  final iap = IAPService(tc);
  return IAPScope(
    service: iap,
    child: ThemeScope(
      controller: tc,
      child: const MaterialApp(home: GameScreen()),
    ),
  );
}

void _phoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1100, 2200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

// Swipes in all directions to ensure at least one valid move is made and registered in history.
Future<void> _makeSureMoveIsMade(WidgetTester tester) async {
  final boardGestureDetector = find.ancestor(
    of: find.byType(AnimatedBoard),
    matching: find.byType(GestureDetector),
  );
  await tester.drag(boardGestureDetector, const Offset(-100, 0));
  await tester.pumpAndSettle();
  await tester.drag(boardGestureDetector, const Offset(100, 0));
  await tester.pumpAndSettle();
  await tester.drag(boardGestureDetector, const Offset(0, -100));
  await tester.pumpAndSettle();
  await tester.drag(boardGestureDetector, const Offset(0, 100));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    // ScoreStore reads from SharedPreferences; provide an in-memory store.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders the title, score header, and New Game button', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_gameScreen());
    await tester.pumpAndSettle();

    expect(find.text('2048'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('BEST'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
  });

  testWidgets('opens the How to Play dialog from the help button', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_gameScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('How to Play'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('starts with exactly two tiles on the board', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_gameScreen());
    await tester.pumpAndSettle();

    // Starting tiles are 2s and/or 4s — there should be exactly two of them.
    final twos = find.text('2').evaluate().length;
    final fours = find.text('4').evaluate().length;
    expect(twos + fours, 2);
  });

  testWidgets('free player can undo a move via rewarded ad (decrementing count)', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_gameScreen());
    await tester.pumpAndSettle();

    // Make sure a move is made
    await _makeSureMoveIsMade(tester);

    // Verify Undo label shows the daily allowance: "Undo (3)"
    expect(find.text('Undo (3)'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo (3)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // The move is undone, and the allowance should decrease by 1
    expect(find.text('Undo (2)'), findsOneWidget);
  });

  testWidgets('premium player gets unlimited undo without daily count', (tester) async {
    _phoneSurface(tester);
    final tc = ThemeController(premiumUnlocked: true);
    await tester.pumpWidget(_gameScreen(controller: tc));
    await tester.pumpAndSettle();

    // Make sure a move is made
    await _makeSureMoveIsMade(tester);

    // Verify Undo label is just "Undo"
    expect(find.text('Undo'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('free player who runs out of undos is directed to paywall', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_gameScreen());
    await tester.pumpAndSettle();

    // Perform 3 moves and undo them to use up the allowance
    for (int i = 0; i < 3; i++) {
      await _makeSureMoveIsMade(tester);
      await tester.tap(find.textContaining('Undo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
    }

    // Make one more move to make another undo possible
    await _makeSureMoveIsMade(tester);

    // Verify label shows Undo and has a lock icon (meaning no allowance remaining)
    expect(find.text('Undo'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);

    // Tap Undo -> should open Paywall Screen
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Paywall screen should be visible
    expect(find.text('Go Premium'), findsOneWidget);
    expect(find.text('Unlock the full experience'), findsOneWidget);
  });
}
