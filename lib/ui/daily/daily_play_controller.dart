import 'package:flutter/foundation.dart';

/// Bridges a daily game's play surface and the Daily screen. The surface pushes
/// its live [metric] (moves or deciseconds) and calls [complete] once when the
/// game ends; the screen listens to drive the live header and the finish flow.
class DailyPlayController extends ChangeNotifier {
  int metric = 0;
  bool started = false;
  bool _completed = false;

  bool get isCompleted => _completed;

  /// Called once when the game ends, with whether it was a success and the
  /// final score. Set by the Daily screen.
  void Function(bool success, int score)? onComplete;

  /// Updates the live values and notifies listeners.
  void update({int? metric, bool? started}) {
    if (metric != null) this.metric = metric;
    if (started != null) this.started = started;
    notifyListeners();
  }

  /// Reports the final result. Idempotent — a second call is ignored.
  void complete(bool success, int score) {
    if (_completed) return;
    _completed = true;
    metric = score;
    onComplete?.call(success, score);
    notifyListeners();
  }
}
