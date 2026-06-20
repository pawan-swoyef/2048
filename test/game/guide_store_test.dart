import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/guide_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a fresh install has not seen any guide', () async {
    final store = GuideStore();
    expect(await store.guideSeen('numbersort'), false);
    expect(await store.guideSeen('magicsquare'), false);
  });

  test('marking a guide seen persists for that game only', () async {
    final store = GuideStore();
    await store.markGuideSeen('numbersort');
    expect(await store.guideSeen('numbersort'), true);
    expect(await store.guideSeen('magicsquare'), false);
  });
}
