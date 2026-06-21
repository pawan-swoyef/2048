import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/magicsquare/hint_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a fresh install grants the daily ad-hint', () async {
    final a = await HintStore().allowance(premium: false, today: '2026-06-19');
    expect(a.remaining, 1);
    expect(a.canHint, true);
  });

  test('recording the ad-hint uses it up for the day', () async {
    final store = HintStore();
    await store.recordHint(today: '2026-06-19');
    final a = await store.allowance(premium: false, today: '2026-06-19');
    expect(a.remaining, 0);
    expect(a.canHint, false);
  });

  test('a new day resets the count', () async {
    final store = HintStore();
    await store.recordHint(today: '2026-06-19');
    final a = await store.allowance(premium: false, today: '2026-06-20');
    expect(a.remaining, 1);
  });

  test('premium ignores the stored count', () async {
    final store = HintStore();
    await store.recordHint(today: '2026-06-19');
    final a = await store.allowance(premium: true, today: '2026-06-19');
    expect(a.unlimited, true);
    expect(a.canHint, true);
  });
}
