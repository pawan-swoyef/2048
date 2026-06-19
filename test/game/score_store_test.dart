import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game2048/game/score_store.dart';

void main() {
  test('bestFor returns 0 for a game with no saved score', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ScoreStore().bestFor('sudoku'), 0);
  });

  test('saveBestFor / bestFor round-trips per game id', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ScoreStore();
    await store.saveBestFor('2048', 12480);
    await store.saveBestFor('daily', 47);
    expect(await store.bestFor('2048'), 12480);
    expect(await store.bestFor('daily'), 47);
  });

  test('migrates the legacy best_score key to the 2048 game id', () async {
    SharedPreferences.setMockInitialValues({'best_score': 5000});
    expect(await ScoreStore().bestFor('2048'), 5000);
  });
}
