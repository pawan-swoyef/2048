import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({
        'last_active_date': '2026-06-18',
      }));

  testWidgets('home hub shows the streak after the daily rollover',
      (tester) async {
    await tester.pumpWidget(const Game2048App());
    await tester.pumpAndSettle();

    // A fresh install rolls over to a 1-day streak, shown on the hub.
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
  });

  testWidgets('claiming the daily gift adds coins on the hub', (tester) async {
    await tester.pumpWidget(const Game2048App());
    await tester.pumpAndSettle();

    expect(find.text('Coins'), findsOneWidget);

    // Tap the glowing gift on the hub — it now opens the Daily Reward screen.
    await tester.tap(find.text('🎁'));
    await tester.pumpAndSettle();

    // Day-1 gift pays 10 coins.
    expect(find.text('Claim +10 Reward'), findsOneWidget);
    await tester.tap(find.text('Claim +10 Reward'));
    await tester.pumpAndSettle();

    // Day-1 gift pays 10 coins -> the coins stat shows 10.
    expect(find.text('10'), findsOneWidget);

    // Flush the toast's auto-dismiss timer.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
