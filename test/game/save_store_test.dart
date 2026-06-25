import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/save_store.dart';

void main() {
  test('load returns null when nothing is saved', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await GameSaveStore().load('2048'), isNull);
  });

  test('save / load round-trips a JSON map', () async {
    SharedPreferences.setMockInitialValues({});
    final store = GameSaveStore();
    await store.save('2048', {
      'score': 12,
      'board': [
        [0, 2],
        [4, 0]
      ],
    });
    final loaded = await store.load('2048');
    expect(loaded, isNotNull);
    expect(loaded!['score'], 12);
    expect(loaded['board'], [
      [0, 2],
      [4, 0]
    ]);
  });

  test('saves are isolated per game id', () async {
    SharedPreferences.setMockInitialValues({});
    final store = GameSaveStore();
    await store.save('numbertap', {'next': 7});
    expect(await store.load('numbersort'), isNull);
    expect((await store.load('numbertap'))!['next'], 7);
  });

  test('clear removes the saved state', () async {
    SharedPreferences.setMockInitialValues({});
    final store = GameSaveStore();
    await store.save('magicsquare', {'a': 1});
    await store.clear('magicsquare');
    expect(await store.load('magicsquare'), isNull);
  });

  test('load returns null for corrupt JSON', () async {
    SharedPreferences.setMockInitialValues({'save_2048': 'not json{'});
    expect(await GameSaveStore().load('2048'), isNull);
  });
}
