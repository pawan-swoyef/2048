import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/game/numbersort/number_sort_game.dart';
import 'package:game2048/ui/numbersort/number_sort_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

Widget _wrap(NumberSortGame game) => MaterialApp(
      home: ThemeScope(
        controller: ThemeController(),
        child: NumberSortScreen(initialGame: game),
      ),
    );

/// Phone-sized surface so the whole layout fits and every column is reachable.
void _phoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1100, 2200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Drags the top token of column [from] onto column [to].
Future<void> _drag(WidgetTester tester, int from, int to) async {
  final start = tester.getCenter(find.byKey(Key('sort-top-$from')));
  final end = tester.getCenter(find.byKey(Key('sort-col-$to')));
  final gesture = await tester.startGesture(start);
  await gesture.moveTo(end);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders the board and controls', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_wrap(NumberSortGame.fromColumns([
      [1, 2, 1],
      [2, 3, 2],
      [3, 1, 3],
      [],
    ])));
    await tester.pump();
    expect(find.text('Restart'), findsOneWidget);
    expect(find.text('Moves'), findsOneWidget);
    expect(find.byKey(const Key('sort-col-3')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a legal drag onto the empty column counts a move',
      (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_wrap(NumberSortGame.fromColumns([
      [1, 2, 1],
      [2, 3, 2],
      [3, 1, 3],
      [],
    ])));
    await tester.pump();

    expect(tester.widget<Text>(find.byKey(const Key('sort-moves'))).data, '0');
    await _drag(tester, 0, 3); // top of col 0 onto the empty col 3
    expect(tester.widget<Text>(find.byKey(const Key('sort-moves'))).data, '1');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('solving the board shows the win card', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_wrap(NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3],
      [3],
    ])));
    await tester.pump();

    await _drag(tester, 3, 2); // last 3 completes column 2
    await tester.pump();

    expect(find.text('PLAY AGAIN'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('first game glows the suggested move; seen game does not',
      (tester) async {
    _phoneSurface(tester);
    final board = NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3],
      [3],
    ]);
    // Fresh install -> guide active.
    await tester.pumpWidget(_wrap(board));
    await tester.pump();

    expect(find.byKey(const Key('sort-guide-from')), findsOneWidget);
    expect(find.byKey(const Key('sort-guide-to')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    // Guide already seen -> no glow.
    SharedPreferences.setMockInitialValues({'guide_seen_numbersort': true});
    await tester.pumpWidget(_wrap(NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3],
      [3],
    ])));
    await tester.pump();

    expect(find.byKey(const Key('sort-guide-from')), findsNothing);
    expect(find.byKey(const Key('sort-guide-to')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('completing the first game persists guide-off for next games',
      (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_wrap(NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3],
      [3],
    ])));
    await tester.pump(); // load guide flag (fresh -> active)
    expect(find.byKey(const Key('sort-guide-from')), findsOneWidget);

    await _drag(tester, 3, 2); // last 3 completes the board -> _finish marks seen
    await tester.pumpAndSettle();

    // A brand-new game must no longer show the guide.
    await tester.pumpWidget(_wrap(NumberSortGame.fromColumns([
      [1, 1, 1],
      [2, 2, 2],
      [3, 3],
      [3],
    ])));
    await tester.pump();
    expect(find.byKey(const Key('sort-guide-from')), findsNothing);
    expect(find.byKey(const Key('sort-guide-to')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
