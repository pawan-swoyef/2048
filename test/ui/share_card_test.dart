import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/ui/share_card.dart';

void main() {
  testWidgets('ShareCard renders the title, result and branding', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ShareCard(
          title: '2048 Daily #128',
          valueLabel: 'You reached',
          value: '512',
          valueSub: 'in 47 moves',
          badge: '🔥 5 day streak',
        ),
      ),
    ));

    expect(find.text('2048 DAILY #128'), findsOneWidget); // upper-cased
    expect(find.text('512'), findsOneWidget);
    expect(find.text('in 47 moves'), findsOneWidget);
    expect(find.text('🔥 5 day streak'), findsOneWidget);
    expect(find.text(kAppName), findsOneWidget);
  });

  testWidgets('OffscreenShareCard exposes a RepaintBoundary at the key',
      (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            OffscreenShareCard(
              boundaryKey: key,
              card: const ShareCard(
                  title: 'Number Tap', valueLabel: 'Your time', value: '12.3s'),
            ),
          ],
        ),
      ),
    ));

    expect(key.currentContext?.findRenderObject(), isA<RenderRepaintBoundary>());
  });
}
