import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/ui/hub/game_registry.dart';

void main() {
  test('registry includes the classic 2048 game with a builder', () {
    final game = kGames.firstWhere((g) => g.id == '2048');
    expect(game.title, isNotEmpty);
    expect(game.builder, isNotNull);
  });

  test('every game has a unique id', () {
    final ids = kGames.map((g) => g.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
