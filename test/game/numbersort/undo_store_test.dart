import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/numbersort/undo_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a fresh install grants the full daily allowance', () async {
    final a = await UndoStore().allowance(premium: false, today: '2026-06-19');
    expect(a.remaining, 3);
    expect(a.canUndo, true);
  });

  test('recording undos reduces the remaining count', () async {
    final store = UndoStore();
    await store.recordUndo(today: '2026-06-19');
    await store.recordUndo(today: '2026-06-19');
    final a = await store.allowance(premium: false, today: '2026-06-19');
    expect(a.remaining, 1);
  });

  test('the daily cap is enforced after three undos', () async {
    final store = UndoStore();
    for (var i = 0; i < 3; i++) {
      await store.recordUndo(today: '2026-06-19');
    }
    final a = await store.allowance(premium: false, today: '2026-06-19');
    expect(a.remaining, 0);
    expect(a.canUndo, false);
  });

  test('a new day resets the used count', () async {
    final store = UndoStore();
    for (var i = 0; i < 3; i++) {
      await store.recordUndo(today: '2026-06-19');
    }
    final a = await store.allowance(premium: false, today: '2026-06-20');
    expect(a.remaining, 3);
  });

  test('recording on a new day starts the count fresh', () async {
    final store = UndoStore();
    await store.recordUndo(today: '2026-06-19');
    await store.recordUndo(today: '2026-06-20'); // new day -> resets then +1
    final a = await store.allowance(premium: false, today: '2026-06-20');
    expect(a.remaining, 2);
  });

  test('premium ignores the stored count', () async {
    final store = UndoStore();
    for (var i = 0; i < 3; i++) {
      await store.recordUndo(today: '2026-06-19');
    }
    final a = await store.allowance(premium: true, today: '2026-06-19');
    expect(a.unlimited, true);
    expect(a.canUndo, true);
  });
}
