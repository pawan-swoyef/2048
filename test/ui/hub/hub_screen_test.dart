import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/iap/iap_service.dart';
import 'package:game2048/ui/hub/hub_screen.dart';
import 'package:game2048/ui/theme_controller.dart';

// The hub picks a random featured game on each open; pin it so tests are
// deterministic. Defaults to 2048, the game most assertions assume.
Widget _wrap({String featured = '2048'}) {
  final tc = ThemeController();
  final iap = IAPService(tc);
  return IAPScope(
    service: iap,
    child: ThemeScope(
      controller: tc,
      child: MaterialApp(home: HubScreen(featuredGameId: featured)),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({
        'last_active_date': '2026-06-20',
      }));

  testWidgets('hub shows the title and featured 2048 game', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Number Games'), findsOneWidget);
    expect(find.text('2048'), findsWidgets);
    expect(find.text('Classic merge puzzle'), findsOneWidget);
    expect(find.text('Play Now'), findsOneWidget);
  });

  testWidgets('featured highlight can be a game other than 2048',
      (tester) async {
    await tester.pumpWidget(_wrap(featured: 'numbertap'));
    await tester.pumpAndSettle();
    // The randomly-picked game headlines the highlight with its own details.
    expect(find.text('Number Tap'), findsOneWidget);
    expect(find.text('Tap 1–25, beat the clock'), findsOneWidget);
    expect(find.text('Play Now'), findsOneWidget);
    // 2048 is no longer forced into the spotlight.
    expect(find.text('Classic merge puzzle'), findsNothing);
  });

  testWidgets('hub shows the streak and coins stats after rollover',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('Coins'), findsOneWidget);
  });

  testWidgets('hub shows the featured game, daily card, and a See all link',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('See all'), findsOneWidget);
    // Daily Challenge is promoted on the hub; other games live behind See all.
    expect(find.text('Daily Challenge'), findsOneWidget);
    expect(find.text('Number Tap'), findsNothing);
  });

  testWidgets('bottom nav has only Home and All Games tabs', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('All Games'), findsOneWidget);
    // The old Stats/Profile tabs are gone.
    expect(find.text('Stats'), findsNothing);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('tapping All Games tab reveals the full game list',
      (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.text('Number Tap'), findsNothing);

    await tester.tap(find.text('All Games'));
    await tester.pumpAndSettle();
    expect(find.text('Number Tap'), findsOneWidget);

    // Scroll down to make Number Sort visible since the banner ad takes up screen space
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Number Sort'), findsOneWidget);
  });

  testWidgets('See all link switches to the All Games tab', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('Number Tap'), findsOneWidget);
  });

  testWidgets('shows IAP paywall screen on first time app open', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Go Premium'), findsOneWidget);
    expect(find.text('Unlock the full experience'), findsOneWidget);
  });
}
