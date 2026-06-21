import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/daily_engagement.dart';
import 'package:game2048/ui/engagement/coin_pill.dart';
import 'package:game2048/ui/engagement/streak_pill.dart';
import 'package:game2048/ui/engagement/daily_gift_button.dart';
import 'package:game2048/ui/engagement/daily_reward_screen.dart';
import 'package:game2048/ui/engagement/streak_sheet.dart';
import 'package:game2048/ui/theme_controller.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: ThemeScope(
        controller: ThemeController(),
        child: Scaffold(body: Center(child: child)),
      ),
    );

// The reward screen brings its own Scaffold, so wrap it without an extra one.
Widget _wrapScreen(Widget child) => MaterialApp(
      home: ThemeScope(controller: ThemeController(), child: child),
    );

void main() {
  testWidgets('CoinPill shows the balance', (tester) async {
    await tester.pumpWidget(_wrap(const CoinPill(coins: 480)));
    expect(find.text('480'), findsOneWidget);
  });

  testWidgets('StreakPill shows the day count and is tappable', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
        _wrap(StreakPill(streak: 5, onTap: () => tapped = true)));
    expect(find.text('5'), findsOneWidget);
    await tester.tap(find.byType(StreakPill));
    expect(tapped, true);
  });

  testWidgets('DailyRewardScreen shows the day reward and claims it',
      (tester) async {
    var claimed = false;
    const progress = PlayerProgress(streakCurrent: 5, giftClaimedDate: '2026-06-07');
    await tester.pumpWidget(_wrapScreen(DailyRewardScreen(
      progress: progress,
      today: DateTime(2026, 6, 8),
      onClaim: () => claimed = true,
    )));

    expect(find.text('+60'), findsOneWidget); // day-5 gift
    await tester.tap(find.text('Claim +60 Reward'));
    expect(claimed, true);
  });

  testWidgets('DailyRewardScreen shows a claimed state when already claimed today',
      (tester) async {
    var claimed = false;
    const progress = PlayerProgress(streakCurrent: 5, giftClaimedDate: '2026-06-08');
    await tester.pumpWidget(_wrapScreen(DailyRewardScreen(
      progress: progress,
      today: DateTime(2026, 6, 8),
      onClaim: () => claimed = true,
    )));

    expect(find.textContaining('Claim'), findsNothing);
    expect(find.textContaining('Come back'), findsWidgets);
    expect(claimed, false);
  });

  testWidgets('DailyRewardScreen shows the 7-day strip with the jackpot day',
      (tester) async {
    const progress = PlayerProgress(streakCurrent: 5, giftClaimedDate: '2026-06-07');
    await tester.pumpWidget(_wrapScreen(DailyRewardScreen(
      progress: progress,
      today: DateTime(2026, 6, 8),
      onClaim: () {},
    )));

    // Scroll down to build off-screen items in the lazy ListView
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('DAY 1'), findsOneWidget);
    expect(find.text('DAY 7'), findsOneWidget);
    expect(find.text('150'), findsOneWidget); // day-7 jackpot coins
  });

  testWidgets('StreakSheet shows current and best streak', (tester) async {
    const progress = PlayerProgress(streakCurrent: 5, streakLongest: 12);
    await tester.pumpWidget(_wrap(const StreakSheet(progress: progress)));
    expect(find.text('5'), findsOneWidget);
    expect(find.textContaining('12'), findsOneWidget);
  });

  testWidgets('DailyGiftButton shows a ready dot only when available', (tester) async {
    await tester.pumpWidget(_wrap(DailyGiftButton(available: true, onTap: () {})));
    expect(find.byKey(const ValueKey('gift-ready-dot')), findsOneWidget);

    await tester.pumpWidget(_wrap(DailyGiftButton(available: false, onTap: () {})));
    expect(find.byKey(const ValueKey('gift-ready-dot')), findsNothing);
  });

  testWidgets('DailyGiftButton is tappable', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(DailyGiftButton(available: true, onTap: () => tapped = true)));
    await tester.tap(find.byType(DailyGiftButton));
    expect(tapped, true);
  });
}
