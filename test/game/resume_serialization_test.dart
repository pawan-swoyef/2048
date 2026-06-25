import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/board.dart';
import 'package:game2048/game/daily/daily_challenge.dart';
import 'package:game2048/game/game_state.dart';
import 'package:game2048/game/magicsquare/magic_square_game.dart';
import 'package:game2048/game/numbersort/number_sort_game.dart';
import 'package:game2048/game/numbertap/number_tap_game.dart';

/// Simulates the real persistence path: encode to a JSON string and decode back
/// to the `Map<String, dynamic>` (with `List<dynamic>`s) that fromJson receives.
Map<String, dynamic> roundTrip(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('GameState (2048) serialization', () {
    test('round-trips a mid-game board, score and flags', () {
      final rng = Random(1);
      var state = GameState.newGame(rng);
      state = state.move(Direction.left, rng);
      state = state.move(Direction.up, rng);

      final back = GameState.fromJson(roundTrip(state.toJson()));

      expect(back.board, state.board);
      expect(back.score, state.score);
      expect(back.best, state.best);
      expect(back.won, state.won);
      expect(back.keepGoing, state.keepGoing);
      expect(back.over, state.over);
    });
  });

  group('NumberTapGame serialization', () {
    test('round-trips tap progress and mistakes', () {
      final game = NumberTapGame(Random(2));
      game.tap(game.next); // correct
      game.tap(99); // a mistake

      final back = NumberTapGame.fromJson(roundTrip(game.toJson()));

      expect(back.board, game.board);
      expect(back.next, game.next);
      expect(back.mistakes, game.mistakes);
    });
  });

  group('NumberSortGame serialization', () {
    test('round-trips columns and move count (undo history resets)', () {
      final game = NumberSortGame.fromColumns([
        [1, 1, 2],
        [2, 2, 1],
        <int>[],
      ], height: 3);
      game.move(0, 2); // top of col 0 onto the empty spare

      final back = NumberSortGame.fromJson(roundTrip(game.toJson()));

      expect(back.columns, game.columns);
      expect(back.moves, game.moves);
      expect(back.height, game.height);
      expect(back.canUndo, isFalse); // undo stack is intentionally not persisted
    });
  });

  group('MagicSquareGame serialization', () {
    test('round-trips grid, clues, tray and solution', () {
      final game = MagicSquareGame(Random(4));
      final hint = game.suggestedPlacement();
      if (hint != null) game.place(hint.value, hint.cell);

      final back = MagicSquareGame.fromJson(roundTrip(game.toJson()));

      expect(back.grid, game.grid);
      expect(back.clue, game.clue);
      expect(back.tray, game.tray);
      expect(back.solution, game.solution);
    });
  });

  group('DailyChallenge serialization', () {
    test('replays history to reproduce the exact board and status', () {
      final challenge = DailyChallenge(seed: 123, puzzleNumber: 1);
      challenge.move(Direction.left);
      challenge.move(Direction.up);
      challenge.move(Direction.right);

      final back = DailyChallenge.fromJson(
        roundTrip(challenge.toJson()),
        seed: 123,
        puzzleNumber: 1,
      );

      expect(back.state.board, challenge.state.board);
      expect(back.state.score, challenge.state.score);
      expect(back.moves, challenge.moves);
      expect(back.status, challenge.status);
      expect(back.history, challenge.history);
    });
  });
}
