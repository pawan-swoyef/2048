import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/ui/numbertap/number_tap_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

Widget _wrap() => MaterialApp(
      home: ThemeScope(controller: ThemeController(), child: const NumberTapScreen()),
    );

/// Use a phone-sized surface so the full layout fits and every tile is tappable.
void _phoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1100, 2200);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders the numbers 1 to 25', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping the next number advances the target', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_wrap());
    await tester.pump();
    expect(find.textContaining('TAP 1'), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(find.textContaining('TAP 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('completing the sequence shows the result', (tester) async {
    _phoneSurface(tester);
    await tester.pumpWidget(_wrap());
    await tester.pump();
    for (var n = 1; n <= 25; n++) {
      await tester.tap(find.text('$n'));
      await tester.pump();
    }
    expect(find.text('Play Again'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
