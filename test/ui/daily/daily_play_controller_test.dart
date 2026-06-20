import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/ui/daily/daily_play_controller.dart';

void main() {
  test('update sets metric/started and notifies listeners', () {
    final c = DailyPlayController();
    var notes = 0;
    c.addListener(() => notes++);
    c.update(metric: 3, started: true);
    expect(c.metric, 3);
    expect(c.started, true);
    expect(notes, 1);
  });

  test('complete fires onComplete once with success and score', () {
    final c = DailyPlayController();
    final calls = <List<Object>>[];
    c.onComplete = (success, score) => calls.add([success, score]);
    c.complete(true, 42);
    c.complete(true, 99); // ignored — already completed
    expect(calls, [
      [true, 42]
    ]);
    expect(c.isCompleted, true);
    expect(c.metric, 42);
  });
}
