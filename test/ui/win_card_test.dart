import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/ui/theme_controller.dart';
import 'package:game2048/ui/win_card.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: ThemeScope(
        controller: ThemeController(),
        child: Scaffold(body: Stack(children: [child])),
      ),
    );

void main() {
  testWidgets('renders every slot when provided', (tester) async {
    var primary = 0, secondary = 0, closed = 0;
    await tester.pumpWidget(_wrap(WinCardOverlay(
      child: WinCard(
        banner: 'SOLVED!',
        headline: 'Great job!',
        stat: const WinStat(label: 'You reached', value: '512', sub: 'in 252 moves'),
        badge: '🔥 1 day daily streak',
        primaryLabel: 'Share Result',
        primaryIcon: Icons.share,
        onPrimary: () => primary++,
        secondaryLabel: 'New Game',
        onSecondary: () => secondary++,
        footerLabel: 'Next puzzle in',
        footerValue: '10h 47m',
        onClose: () => closed++,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('SOLVED!'), findsOneWidget);
    expect(find.text('Great job!'), findsOneWidget);
    expect(find.text('512'), findsOneWidget);
    expect(find.text('in 252 moves'), findsOneWidget);
    expect(find.text('🔥 1 day daily streak'), findsOneWidget);
    expect(find.text('SHARE RESULT'), findsOneWidget); // primary upper-cases
    expect(find.text('New Game'), findsOneWidget);
    expect(find.text('10h 47m'), findsOneWidget);

    await tester.tap(find.text('SHARE RESULT'));
    await tester.tap(find.text('New Game'));
    await tester.tap(find.byIcon(Icons.close));
    expect(primary, 1);
    expect(secondary, 1);
    expect(closed, 1);
  });

  testWidgets('hides optional slots when omitted', (tester) async {
    await tester.pumpWidget(_wrap(WinCardOverlay(
      child: WinCard(
        headline: 'Done!',
        stat: const WinStat(label: 'Your time', value: '12.3s'),
        primaryLabel: 'Play Again',
        onPrimary: () {},
        celebrate: false,
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('12.3s'), findsOneWidget);
    expect(find.text('PLAY AGAIN'), findsOneWidget);
    // No close button, no secondary, no footer.
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
