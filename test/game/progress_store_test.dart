import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/daily_engagement.dart';
import 'package:game2048/game/progress_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loads sensible defaults on a fresh install', () async {
    final p = await ProgressStore().load();
    expect(p.coins, 0);
    expect(p.streakCurrent, 0);
    expect(p.streakLongest, 0);
    expect(p.lastActiveDate, isNull);
    expect(p.giftClaimedDate, isNull);
    expect(p.streakFreezes, 1);
  });

  test('round-trips a saved progress', () async {
    final store = ProgressStore();
    const saved = PlayerProgress(
      coins: 480,
      streakCurrent: 5,
      streakLongest: 12,
      lastActiveDate: '2026-06-08',
      giftClaimedDate: '2026-06-08',
      streakFreezes: 0,
    );
    await store.save(saved);

    final loaded = await store.load();
    expect(loaded.coins, 480);
    expect(loaded.streakCurrent, 5);
    expect(loaded.streakLongest, 12);
    expect(loaded.lastActiveDate, '2026-06-08');
    expect(loaded.giftClaimedDate, '2026-06-08');
    expect(loaded.streakFreezes, 0);
  });
}
