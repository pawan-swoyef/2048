import 'package:audioplayers/audioplayers.dart';

/// Plays the game's short sound effects. Each effect has its own reusable
/// player so rapid moves don't cut each other off awkwardly. All playback is
/// guarded so audio failures (e.g. browser autoplay rules) never crash the game.
class SoundService {
  static const _names = ['move', 'merge', 'win', 'lose', 'coin'];

  final Map<String, AudioPlayer> _players = {};
  bool enabled = true;

  SoundService() {
    for (final name in _names) {
      _players[name] = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    }
  }

  Future<void> _play(String name) async {
    if (!enabled) return;
    final player = _players[name];
    if (player == null) return;
    try {
      await player.stop();
      await player.play(AssetSource('sounds/$name.wav'));
    } catch (_) {
      // Ignore playback errors (autoplay blocked, unsupported platform, etc.).
    }
  }

  void move() => _play('move');
  void merge() => _play('merge');
  void win() => _play('win');
  void lose() => _play('lose');
  void coin() => _play('coin');

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
  }
}
