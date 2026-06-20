import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/game/magicsquare/magic_square_game.dart';
import 'package:game2048/ui/magicsquare/magic_square_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

const _sol = [2, 7, 6, 9, 5, 1, 4, 3, 8];

// ThemeScope sits above MaterialApp (as in main.dart) so dialogs pushed onto
// the navigator can still find it.
Widget _wrap(MagicSquareGame game, {bool premium = false}) => ThemeScope(
      controller: ThemeController(premiumUnlocked: premium),
      child: MaterialApp(home: MagicSquareScreen(initialGame: game)),
    );

void _phoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1100, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

Future<void> _drag(WidgetTester tester, Key from, Key to) async {
  final gesture = await tester.startGesture(tester.getCenter(find.byKey(from)));
  await gesture.moveTo(tester.getCenter(find.byKey(to)));
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders the grid, tray and hint button', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_wrap(MagicSquareGame.fromSolution(_sol, {0, 1, 2})));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ms-cell-0')), findsOneWidget);
    expect(find.byKey(const Key('ms-hint')), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dragging the last number into place solves the puzzle',
      (tester) async {
    _phoneSurface(tester);
    // 8 clue cells; only cell 8 empty, tray holds its value (8).
    await tester.pumpWidget(_wrap(
        MagicSquareGame.fromSolution(_sol, {0, 1, 2, 3, 4, 5, 6, 7})));
    await tester.pumpAndSettle();

    await _drag(tester, const Key('ms-tray-8'), const Key('ms-cell-8'));
    await tester.pump();

    expect(find.text('NEW PUZZLE'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a free player sees the Watch Ad / Go Premium dialog',
      (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(
        _wrap(MagicSquareGame.fromSolution(_sol, {0, 1, 2, 3})));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ms-hint')));
    await tester.pumpAndSettle();

    expect(find.text('Watch Ad'), findsOneWidget);
    expect(find.text('Go Premium'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('first game glows the suggested move; seen game does not',
      (tester) async {
    _phoneSurface(tester);
    // Fresh install -> guide active.
    await tester.pumpWidget(_wrap(MagicSquareGame.fromSolution(_sol, {0, 1, 2, 3})));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ms-guide-tray')), findsOneWidget);
    expect(find.byKey(const Key('ms-guide-cell')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    // Guide already seen -> no glow.
    SharedPreferences.setMockInitialValues({'guide_seen_magicsquare': true});
    await tester.pumpWidget(_wrap(MagicSquareGame.fromSolution(_sol, {0, 1, 2, 3})));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ms-guide-tray')), findsNothing);
    expect(find.byKey(const Key('ms-guide-cell')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a premium player gets a hint with no dialog', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(
        _wrap(MagicSquareGame.fromSolution(_sol, {0, 1, 2, 3}), premium: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ms-hint')));
    await tester.pump();

    expect(find.text('Watch Ad'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('completing the first game persists guide-off for next games',
      (tester) async {
    _phoneSurface(tester);
    // 8 clue cells; only cell 8 empty, tray holds its value (8).
    await tester.pumpWidget(_wrap(
        MagicSquareGame.fromSolution(_sol, {0, 1, 2, 3, 4, 5, 6, 7})));
    await tester.pumpAndSettle(); // load guide flag (fresh -> active)
    expect(find.byKey(const Key('ms-guide-tray')), findsOneWidget);

    await _drag(tester, const Key('ms-tray-8'), const Key('ms-cell-8')); // solves
    await tester.pumpAndSettle();

    // A brand-new puzzle with empty cells must no longer show the guide.
    await tester.pumpWidget(
        _wrap(MagicSquareGame.fromSolution(_sol, {0, 1, 2, 3})));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ms-guide-tray')), findsNothing);
    expect(find.byKey(const Key('ms-guide-cell')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
