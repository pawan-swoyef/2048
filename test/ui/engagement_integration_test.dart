import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game2048/main.dart';
import 'package:game2048/ui/engagement/coin_pill.dart';
import 'package:game2048/ui/engagement/daily_gift_button.dart';
import 'package:game2048/ui/engagement/streak_pill.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home screen shows the streak after the daily rollover',
      (tester) async {
    await tester.pumpWidget(const Game2048App());
    await tester.pumpAndSettle();

    // A fresh install rolls over to a 1-day streak.
    expect(find.byType(StreakPill), findsOneWidget);
    expect(find.widgetWithText(StreakPill, '1'), findsOneWidget);
  });

  testWidgets('claiming the daily gift adds coins on the home screen',
      (tester) async {
    await tester.pumpWidget(const Game2048App());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(CoinPill, '0'), findsOneWidget);

    await tester.tap(find.byType(DailyGiftButton));
    await tester.pumpAndSettle();

    expect(find.text('Claim Reward'), findsOneWidget);
    await tester.tap(find.text('Claim Reward'));
    await tester.pumpAndSettle();

    // Day-1 gift pays 10 coins.
    expect(find.widgetWithText(CoinPill, '10'), findsOneWidget);

    // Flush the toast's auto-dismiss timer.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
